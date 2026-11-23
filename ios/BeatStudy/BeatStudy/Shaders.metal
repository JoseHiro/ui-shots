#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Water

/// A thin layer of water over everything below `top`. Each ripple is four floats:
/// centre x, centre y, age in seconds, strength. The surface bends what is under it,
/// mirrors what stands above it, and catches a highlight on every wave.
[[ stitchable ]] half4 water(float2 pos, SwiftUI::Layer layer, float2 size, float time, float top,
                            device const float *rip, int count, float shimmer, float mirror) {
    if (pos.y < top) return layer.sample(pos);
    float2 grad = float2(0);
    for (int i = 0; i + 3 < count; i += 4) {
        float2 c = float2(rip[i], rip[i + 1]);
        float age = rip[i + 2], amp = rip[i + 3];
        if (age < 0) continue;
        float2 dv = pos - c;
        float d = max(length(dv), 0.001);
        float x = d - age * 240.0;
        float w = 26.0 + age * 14.0, k = 0.11;
        float env = amp * exp(-age * 1.15) * exp(-x * x / (2.0 * w * w)) / (1.0 + d / 420.0);
        float dd = env * (k * cos(x * k) - x / (w * w) * sin(x * k));
        grad += dv / d * dd;
    }
    // Restless surface: two slow swells and fine shimmer from the hats.
    grad += shimmer * 0.07 * float2(cos(pos.x * 0.045 + time * 1.3) * 0.35 + cos(pos.x * 0.21 - pos.y * 0.13 + time * 5.0) * 0.12,
                             cos(pos.y * 0.05 - time * 1.1) * 0.35 + cos(pos.y * 0.19 + pos.x * 0.15 + time * 4.3) * 0.12);
    float2 off = grad * 16.0;
    half4 col = layer.sample(pos + off);
    float depth = pos.y - top;
    // Mirror image of what stands above the waterline, weaker further out.
    float2 rp = float2(pos.x, top - depth * 0.92) + off * 2.2;
    half4 refl = (mirror > 0.0 && rp.y > 0) ? layer.sample(rp) : half4(0);
    float fres = mirror * (0.62 - 0.42 * smoothstep(0.0, 520.0, depth));
    col.rgb = col.rgb + refl.rgb * half(fres) * (1.0h - col.rgb * 0.6h);
    // Highlights on the slopes facing the light, and a bright meniscus at the edge.
    float3 n = normalize(float3(-grad * 1.1, 1.0));
    float spec = pow(max(dot(n, normalize(float3(-0.25, -0.35, 0.9))), 0.0), 60.0);
    float spec2 = pow(max(dot(n, normalize(float3(0.3, 0.2, 0.93))), 0.0), 120.0);
    float edge = exp(-depth * 0.35) * 0.55;
    col.rgb += half3(1.0, 0.93, 0.95) * half(spec * 0.45 + spec2 * 0.3 + edge);
    return col;
}

// MARK: - Ferrofluid

static float hexSpike(float2 p, float spacing, float radius) {
    float2 s = float2(1.0, 1.7320508) * spacing;
    float2 a = fmod(p, s) - s * 0.5;
    float2 b = fmod(p - s * 0.5, s) - s * 0.5;
    a = select(a, a + s, a < -s * 0.5);
    b = select(b, b + s, b < -s * 0.5);
    float d = min(length(a), length(b));
    float k = max(0.0, 1.0 - d / radius);
    return k * k * (1.6 - 0.6 * k);
}

/// The puddle's rim, gently lobed and drifting so it never looks like a perfect disc.
static float rimR(float2 q, float R, float time) {
    float a = atan2(q.y, q.x);
    return R * (1.0 + 0.035 * sin(a * 5.0 + time * 1.7) + 0.02 * sin(a * 9.0 - time * 2.3));
}

static float ferroHeight(float2 p, float2 c, float R0, float spikes, float time) {
    float d = length(p - c);
    float R = rimR(p - c, R0, time);
    float dome = sqrt(max(0.0, 1.0 - (d / R) * (d / R)));
    float inner = smoothstep(R * 0.98, R * 0.35, d);
    float2 q = p - c;
    float h = dome * 26.0;
    float wob = 1.0 + 0.08 * sin(time * 3.0 + q.x * 0.05) * sin(time * 2.3 + q.y * 0.06);
    h += spikes * inner * wob * hexSpike(q + float2(500.0), 23.0, 11.5) * (0.55 + 0.45 * dome);
    return h;
}

/// Black ferrofluid in a dish: a glossy dome that grows spikes with the bass.
[[ stitchable ]] half4 ferro(float2 pos, half4 color, float2 size, float time, float2 centre, float radius, float spikes) {
    float d = length(pos - centre);
    if (d > radius * 1.06 + 2.0) return half4(0);
    float rim = rimR(pos - centre, radius, time);
    float e = 0.75;
    float h = ferroHeight(pos, centre, radius, spikes, time);
    float hx = ferroHeight(pos + float2(e, 0), centre, radius, spikes, time) - h;
    float hy = ferroHeight(pos + float2(0, e), centre, radius, spikes, time) - h;
    float3 n = normalize(float3(-hx / e, -hy / e, 1.0));
    float3 v = float3(0, 0, 1);
    float3 r = reflect(-v, n);
    // Studio: a big soft box above-left, a strip light on the right, a pale floor.
    float box = smoothstep(0.55, 0.85, dot(r, normalize(float3(-0.45, -0.7, 0.55))));
    float strip = smoothstep(0.9, 0.97, dot(r, normalize(float3(0.75, -0.1, 0.65))));
    float floorGlow = smoothstep(-0.2, 0.6, r.y) * 0.18;
    float fres = 0.04 + 0.96 * pow(1.0 - max(n.z, 0.0), 4.0);
    float3 col = float3(0.018, 0.018, 0.024);
    col += (box * 0.95 + strip * 0.7 + floorGlow) * (0.25 + 0.75 * fres) * float3(0.95, 0.97, 1.0);
    col += pow(max(dot(n, normalize(float3(-0.4, -0.6, 0.7))), 0.0), 90.0) * 0.9;
    float a = smoothstep(rim + 1.5, rim - 1.5, d);
    return half4(half3(col) * half(a), half(a));
}

// MARK: - Fire

static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float vnoise(float2 p) {
    float2 i = floor(p), f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + float2(1, 0)), u.x),
               mix(hash21(i + float2(0, 1)), hash21(i + float2(1, 1)), u.x), u.y);
}

static float fbm(float2 p) {
    float s = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) { s += a * vnoise(p); p = p * 2.03 + float2(17.1, 9.2); a *= 0.5; }
    return s;
}

/// Flames rising from the bottom edge. `height` is 0...1 of the box, `flare` adds a burst.
[[ stitchable ]] half4 fire(float2 pos, half4 color, float2 size, float time, float height, float flare) {
    float2 uv = pos / size;
    float y = 1.0 - uv.y;                  // 0 at the logs, 1 at the top
    float x = (uv.x - 0.5) * 2.0;
    float n = fbm(float2(uv.x * 5.0, y * 3.2 - time * 2.4));
    float n2 = fbm(float2(uv.x * 9.0 + 3.0, y * 6.0 - time * 4.1));
    float H = max(0.04, height);
    float width = 0.95 - y / H * 0.75;
    float body = width - abs(x + (n - 0.5) * 0.5 * y) * 1.25;
    float i = body + (n - 0.5) * 1.1 + (n2 - 0.5) * 0.35 - (y / H) * 0.55 + flare * 0.25;
    i *= smoothstep(H * 1.25, H * 0.2, y);
    i = clamp(i * 1.6, 0.0, 1.0);
    float3 c = mix(float3(0.45, 0.04, 0.0), float3(1.0, 0.36, 0.03), smoothstep(0.05, 0.4, i));
    c = mix(c, float3(1.0, 0.78, 0.32), smoothstep(0.4, 0.75, i));
    c = mix(c, float3(1.0, 0.97, 0.85), smoothstep(0.75, 1.0, i));
    float a = smoothstep(0.02, 0.25, i);
    return half4(half3(c) * half(a), half(a));
}
