#include <flutter/runtime_effect.glsl>

uniform float uProgress;   
uniform vec2 uResolution;  
uniform sampler2D uTexture;  

vec4 fragment(vec2 uv, vec2 fragCoord) {
    float size = 40.0 * (1.0 - uProgress) + 1.0;
    vec2 grid = floor(fragCoord / size) * size;
    vec4 color = texture(uTexture, grid / uResolution);
    float alpha = step(0.0, uProgress - (uv.x + uv.y) / 2.0); 
    return color * uProgress;
}