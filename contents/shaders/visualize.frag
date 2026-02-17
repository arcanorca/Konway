#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 aliveColor;
    vec4 deadColor;
    vec4 backgroundColor;
    float contrast;
    float safeMode;
    float safeSaturation;
    float dyingPower;
    vec2 texSize;
    float cellShapeMode;
    float goBoardGrid;
} ubuf;

layout(binding = 1) uniform sampler2D stateTexture;
layout(binding = 2) uniform sampler2D prevStateTexture;

void main()
{
    float alive = step(0.5, texture(stateTexture, qt_TexCoord0).r);
    float prevAlive = step(0.5, texture(prevStateTexture, qt_TexCoord0).r);
    float dying = (1.0 - alive) * prevAlive * clamp(ubuf.dyingPower, 0.0, 1.0);
    float activity = max(alive, dying);

    vec2 cellUv = fract(qt_TexCoord0 * ubuf.texSize);
    vec2 centeredUv = cellUv - vec2(0.5);
    float dist2 = dot(centeredUv, centeredUv);
    float circleMask = 1.0 - smoothstep(0.20, 0.26, dist2);
    float roundedMode = step(0.5, ubuf.cellShapeMode);
    float shapedActivity = activity * mix(1.0, circleMask, roundedMode);

    float centered = (shapedActivity - 0.5) * ubuf.contrast + 0.5;
    float balanced = clamp(centered, 0.0, 1.0);
    vec3 color = mix(ubuf.deadColor.rgb, ubuf.aliveColor.rgb, balanced);
    color = mix(ubuf.backgroundColor.rgb, color, 0.9);

    if (ubuf.goBoardGrid > 0.5) {
        float edgeDist = min(min(cellUv.x, 1.0 - cellUv.x), min(cellUv.y, 1.0 - cellUv.y));
        float gridLine = 1.0 - smoothstep(0.0, 0.06, edgeDist);
        float bgLuma = dot(ubuf.backgroundColor.rgb, vec3(0.2126, 0.7152, 0.0722));
        float lighten = mix(0.10, 0.24, 1.0 - bgLuma);
        vec3 gridColor = mix(ubuf.backgroundColor.rgb, vec3(1.0), lighten);
        float gridAlpha = gridLine * mix(0.24, 0.08, shapedActivity);
        color = mix(color, gridColor, gridAlpha);
    }

    if (ubuf.safeMode > 0.5) {
        float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
        color = mix(vec3(luma), color, clamp(ubuf.safeSaturation, 0.0, 1.0));
    }

    fragColor = vec4(color, 1.0) * ubuf.qt_Opacity;
}
