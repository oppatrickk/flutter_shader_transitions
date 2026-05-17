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

void main() {
    // Uniform cross-fade: the incoming layer's opacity ramps 0→1 evenly.
    float alpha = clamp(uProgress, 0.0, 1.0);
    alpha = mix(alpha, 1.0 - alpha, uInvert);
    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
