#version 440

// Reduces the simulation grid to a coarse tile map for the Adaptive injector.
// One output pixel per tile:  R = fraction of alive cells,  G = fraction of cells
// that changed since the previous generation.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 texSize;
    vec2 tiles;
    float nonce;
    float _padding0;
} ubuf;

layout(binding = 1) uniform sampler2D stateTexture;
layout(binding = 2) uniform sampler2D prevStateTexture;

void main()
{
    vec2 safeTiles = max(ubuf.tiles, vec2(1.0));
    vec2 safeSize = max(ubuf.texSize, vec2(1.0));
    vec2 tile = min(floor(qt_TexCoord0 * safeTiles), safeTiles - vec2(1.0));

    vec2 c0 = floor(tile * safeSize / safeTiles);
    vec2 c1 = floor((tile + vec2(1.0)) * safeSize / safeTiles);
    vec2 span = max(c1 - c0, vec2(1.0));
    // Visit every cell of small tiles; subsample evenly when a tile is wider than 16 cells.
    vec2 stride = max(span / 16.0, vec2(1.0));

    float alive = 0.0;
    float changed = 0.0;
    float total = 0.0;

    for (int y = 0; y < 16; ++y) {
        float fy = c0.y + float(y) * stride.y;
        if (fy >= max(c1.y, c0.y + 1.0)) {
            break;
        }
        for (int x = 0; x < 16; ++x) {
            float fx = c0.x + float(x) * stride.x;
            if (fx >= max(c1.x, c0.x + 1.0)) {
                break;
            }
            vec2 uv = (floor(vec2(fx, fy)) + vec2(0.5)) / safeSize;
            float a = step(0.5, texture(stateTexture, uv).r);
            float p = step(0.5, texture(prevStateTexture, uv).r);
            alive += a;
            changed += abs(a - p);
            total += 1.0;
        }
    }

    float inv = 1.0 / max(total, 1.0);
    fragColor = vec4(alive * inv, changed * inv, ubuf.nonce * 0.0, 1.0) * ubuf.qt_Opacity;
}
