#version 460 core
#include <flutter/runtime_effect.glsl>

// Shared uniform layout v3 (set unconditionally by ShaderMaskTransition):
//  0    uProgress   — phase progress 0→1
//  1-2  uResolution — bounds px
//  3-4  uOrigin     — normalized [0,1] center
//  5-6  uDirection   — unused by polygon
//  7    uFeather     — edge softness px
//  8    uCellSize    — unused by polygon
//  9    uRotation    — polygon orientation, radians
//  10   uInvert      — 0/1 expanding vs contracting
//  11   uSectors     — unused by polygon
//  12   uSides       — polygon side count (≥ 3; high ≈ circle)
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

    // Regular polygon "apothem distance": fold the angle into one sector and
    // project the radius onto the sector bisector.
    float n = max(uSides, 3.0);
    float sector = TAU / n;
    float ang = atan(v.y, v.x) + uRotation;
    float aa = mod(ang, sector) - sector * 0.5;
    float pd = length(v) * cos(aa);

    // Farthest screen corner from the origin → at uProgress=1 the polygon's
    // apothem reaches it, so the screen is always fully covered.
    float maxDist = max(
        max(length(origin), length(vec2(uResolution.x, 0.0) - origin)),
        max(length(vec2(0.0, uResolution.y) - origin),
            length(uResolution - origin))
    );

    float nd = pd / maxDist;
    float feather = max(uFeather / maxDist, 0.002);
    float a = 1.0 - smoothstep(uProgress - feather, uProgress + feather, nd);
    float alpha = mix(a, 1.0 - a, uInvert);

    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
