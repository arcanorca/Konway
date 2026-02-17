#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 texSize;
    float nonce;
    float _padding0;
    float _padding1;
} ubuf;

layout(binding = 1) uniform sampler2D stateTexture;

void main()
{
    vec2 uv = clamp(qt_TexCoord0 + vec2(ubuf.nonce * 1e-9), vec2(0.0), vec2(1.0));
    vec2 safeTexSize = max(ubuf.texSize, vec2(1.0));
    vec2 pixel = floor(uv * safeTexSize);
    vec2 stateUv = (pixel + vec2(0.5)) / safeTexSize;
    float alive = texture(stateTexture, stateUv).r;
    fragColor = vec4(alive, alive, alive, 1.0) * ubuf.qt_Opacity;
}
