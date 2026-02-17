#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 texSize;
    float density;
    float randomSeed;
    float wrapEdges;
    float seedMode;
    float applyStamp;
    float applyKill;
    float bornMask;
    float surviveMask;
    vec4 clockRect;
    float clockEnabled;
    float clockPad;
    float _padding0;
    float _padding1;
} ubuf;

layout(binding = 1) uniform sampler2D prevState;
layout(binding = 2) uniform sampler2D stampTexture;
layout(binding = 3) uniform sampler2D killTexture;

float hash21(vec2 p)
{
    vec2 seeded = p + vec2(ubuf.randomSeed * 0.73, ubuf.randomSeed * 1.37);
    return fract(sin(dot(seeded, vec2(127.1, 311.7))) * 43758.5453123);
}

float smoothHashNoise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float sampleAlive(vec2 pixel)
{
    vec2 coord = pixel;
    if (ubuf.wrapEdges > 0.5) {
        coord = mod(coord + ubuf.texSize, ubuf.texSize);
    } else {
        if (coord.x < 0.0 || coord.y < 0.0 || coord.x >= ubuf.texSize.x || coord.y >= ubuf.texSize.y) {
            return 0.0;
        }
    }

    vec2 uv = (coord + vec2(0.5)) / ubuf.texSize;
    return step(0.5, texture(prevState, uv).r);
}

float isRuleBitSet(float mask, float neighborCount)
{
    float bit = exp2(neighborCount);
    float shifted = floor(mask / bit);
    return step(0.5, mod(shifted, 2.0));
}

bool isInsideClockIsolation(vec2 pixel)
{
    if (ubuf.clockEnabled < 0.5) {
        return false;
    }
    float pad = max(0.0, ubuf.clockPad);
    float x0 = ubuf.clockRect.x - pad;
    float y0 = ubuf.clockRect.y - pad;
    float x1 = ubuf.clockRect.x + ubuf.clockRect.z + pad;
    float y1 = ubuf.clockRect.y + ubuf.clockRect.w + pad;
    return pixel.x >= x0 && pixel.y >= y0 && pixel.x < x1 && pixel.y < y1;
}

void main()
{
    vec2 pixel = floor(qt_TexCoord0 * ubuf.texSize);

    float alive;
    if (ubuf.seedMode > 0.5) {
        vec2 uv = (pixel + vec2(0.5)) / max(ubuf.texSize, vec2(1.0));
        vec2 seedOffset = vec2(ubuf.randomSeed * 0.0013, ubuf.randomSeed * 0.0019);

        float largeScale = smoothHashNoise(uv * 9.0 + seedOffset);
        float midScale = smoothHashNoise(uv * 21.0 + seedOffset * 1.7 + vec2(3.7, 11.3));
        float fineScale = hash21(pixel + vec2(17.0, 47.0));

        float organic = largeScale * 0.58 + midScale * 0.30 + fineScale * 0.12;
        float baseThreshold = mix(0.90, 0.42, clamp(ubuf.density, 0.01, 0.90));
        float patchBias = smoothstep(0.40, 0.82, largeScale) * 0.12;
        float threshold = clamp(baseThreshold - patchBias, 0.35, 0.98);
        alive = organic > threshold ? 1.0 : 0.0;
    } else {
        float neighbors = 0.0;
        for (int oy = -1; oy <= 1; ++oy) {
            for (int ox = -1; ox <= 1; ++ox) {
                if (ox == 0 && oy == 0) {
                    continue;
                }
                neighbors += sampleAlive(pixel + vec2(float(ox), float(oy)));
            }
        }

        float current = sampleAlive(pixel);
        float n = clamp(floor(neighbors + 0.5), 0.0, 8.0);
        float born = isRuleBitSet(ubuf.bornMask, n);
        float survive = isRuleBitSet(ubuf.surviveMask, n);
        alive = current > 0.5 ? survive : born;
    }

    if (ubuf.applyKill > 0.5) {
        float kill = step(0.5, texture(killTexture, (pixel + vec2(0.5)) / ubuf.texSize).r);
        alive *= (1.0 - kill);
    }
    if (ubuf.applyStamp > 0.5) {
        float stamp = step(0.5, texture(stampTexture, (pixel + vec2(0.5)) / ubuf.texSize).r);
        alive = max(alive, stamp);
    }
    if (isInsideClockIsolation(pixel)) {
        alive = 0.0;
    }

    fragColor = vec4(alive, 0.0, 0.0, 1.0) * ubuf.qt_Opacity;
}
