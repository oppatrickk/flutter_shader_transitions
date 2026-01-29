#version 460 core
#include <flutter/runtime_effect.glsl>

uniform float uProgress;     // 0.0 to 1.0
uniform vec2 uResolution;    // Screen size
uniform float uDiamondSize;  // Size of diamonds in pixels

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution.xy;
    vec2 fragCoord = FlutterFragCoord().xy;

    // 1. Divide screen into grids
    float xFraction = fract(fragCoord.x / uDiamondSize);
    float yFraction = fract(fragCoord.y / uDiamondSize);

    // 2. Calculate diamond shape (Manhattan distance from center of grid cell)
    float xDistance = abs(xFraction - 0.5);
    float yDistance = abs(yFraction - 0.5);

    // 3. Apply the sweeping logic (progress + screen position offset)
    // We use a multiplier (e.g., 4.0) to ensure the sweep finishes completely
    if (xDistance + yDistance + uv.x + uv.y > uProgress * 4.0) {
        // Transparent (the scene underneath shows)
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
    } else {
        // Black (the transition color)
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
}