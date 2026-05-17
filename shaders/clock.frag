#version 460 core
#include <flutter/runtime_effect.glsl>

// Shared uniform layout v3 (set unconditionally by ShaderMaskTransition):
//  0    uProgress   — phase progress 0→1
//  1-2  uResolution — bounds px
//  3-4  uOrigin     — normalized [0,1] pivot
//  5-6  uDirection   — unused by clock
//  7    uFeather     — edge softness px
//  8    uCellSize    — unused by clock
//  9    uRotation    — start angle, radians
//  10   uInvert      — 0/1 sweep direction (CW/CCW)
//  11   uSectors     — number of radial sectors (≥ 1)
//  12   uSides       — unused by clock
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

const float TAU = 6.28318530718;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 origin = uOrigin * uResolution;
    vec2 v = fragCoord - origin;

    // Angle around the pivot, rotated by uRotation, normalized to [0,1).
    float ang = atan(v.y, v.x) - uRotation;
    float a = fract(ang / TAU + 1.0);

    // Fold into `sectors` identical wedges so the sweep fans out.
    float sectors = max(uSectors, 1.0);
    float swept = fract(a * sectors);

    swept = mix(swept, 1.0 - swept, uInvert);

    // Feather in angular units (uFeather px ≈ at mid-radius).
    float feather = max(uFeather / max(uResolution.x, uResolution.y), 0.002);
    float alpha = 1.0 - smoothstep(uProgress - feather, uProgress + feather, swept);

    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
