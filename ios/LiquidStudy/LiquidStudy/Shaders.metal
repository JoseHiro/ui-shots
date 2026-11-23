#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Mercury

/// Metaball field of the droplets (x, y, radius, tint r, g, b each). 0.171 at a lone
/// droplet's edge; droplets that come close melt into one.
static float dropField(float2 p, device const float *dr, int dn, thread float3 &tint) {
    float F = 0.0, ws = 1e-4;
    float3 tc = float3(0);
    for (int i = 0; i + 5 < dn; i += 6) {
        float r = dr[i + 2];
        if (r <= 0.5) continue;
        float2 dv = p - float2(dr[i], dr[i + 1]);
        float R = r * 1.5;
        float q = 1.0 - dot(dv, dv) / (R * R);
        if (q <= 0.0) continue;
        float f = q * q * q;
        F += f;
        tc += f * float3(dr[i + 3], dr[i + 4], dr[i + 5]);
        ws += f;
    }
    tint = tc / ws;
    return F;
}

static float mercuryHeight(float2 p, device const float *dr, int dn, device const float *rip, int rn, float time, thread float &F, thread float3 &tint) {
    F = dropField(p, dr, dn, tint);
    float inside = smoothstep(0.171, 0.4, F);
    float h = smoothstep(0.171, 0.5, F) * 30.0;
    for (int i = 0; i + 3 < rn; i += 4) {
        float age = rip[i + 2], amp = rip[i + 3];
        if (age < 0) continue;
        float d = length(p - float2(rip[i], rip[i + 1]));
        float x = d - age * 260.0;
        float w = 16.0 + age * 10.0;
        h += inside * amp * 0.9 * exp(-age * 1.0) * exp(-x * x / (2.0 * w * w)) * cos(x * 0.14);
    }
    h += inside * 0.5 * sin(p.x * 0.05 + time * 2.0) * sin(p.y * 0.045 - time * 1.6);
    return h;
}

/// Liquid metal seen from above by an eye at height `eye.z` over `eye.xy`. It mirrors the
/// ceiling (`ceil` pt above): two strip lights and the album sleeve `art` hanging over
/// `centre` (`cover` = its width, `show` = how much it shows instead of each droplet's own tint).
[[ stitchable ]] half4 mercury(float2 pos, half4 color, float2 size, float time, float3 eye, float ceil, float2 centre, float cover,
                              texture2d<half> art, float show,
                              device const float *dr, int dn, device const float *rip, int rn) {
    float F, Fx, Fy;
    float3 tint, tt;
    float h = mercuryHeight(pos, dr, dn, rip, rn, time, F, tint);
    if (F < 0.12) return half4(0);
    float hx = mercuryHeight(pos + float2(1, 0), dr, dn, rip, rn, time, Fx, tt) - h;
    float hy = mercuryHeight(pos + float2(0, 1), dr, dn, rip, rn, time, Fy, tt) - h;
    float3 n = normalize(float3(-hx, -hy, 1.0));
    float3 P = float3(pos, h);
    float3 r = reflect(normalize(P - eye), n);
    float3 col;
    if (r.z > 0.02) {
        float2 hit = P.xy + r.xy * (ceil - h) / r.z;
        // Ceiling: dark, a soft glow over the middle and two long strip lights.
        float2 g = (hit - centre) / 500.0;
        col = float3(0.09, 0.095, 0.105) + 0.16 * exp(-dot(g, g) * 2.0);
        float strips = smoothstep(44.0, 26.0, abs(abs(hit.x - centre.x) - 250.0)) * smoothstep(760.0, 600.0, abs(hit.y - centre.y));
        col += float3(0.97, 0.98, 1.0) * strips;
        // Before a record is picked each droplet is tinged with its own record's colour.
        col = mix(col, tint * 0.85 + col * 0.3, (1.0 - show) * 0.4);
        float2 uv = (hit - centre) / cover + 0.5;
        float inCover = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
        constexpr sampler smp(address::clamp_to_edge, filter::linear);
        float3 sleeve = float3(art.sample(smp, clamp(uv, 0.0, 1.0)).rgb);
        col = mix(col, mix(tint, sleeve, show), inCover);
    } else {
        col = float3(0.55, 0.57, 0.6);
    }
    float fres = pow(1.0 - n.z, 3.0);
    col = col * (0.84 + 0.16 * fres) + fres * 0.22;
    float a = smoothstep(0.155, 0.19, F);
    return half4(half3(col) * half(a), half(a));
}

// MARK: - Sumi (paper marbling)

/// Suminagashi: ink and clear water dropped onto still water, each drop pushing every
/// earlier ring outward so the area is kept. `op` holds 8 floats per event, oldest first:
/// kind (0 drop, 1 swirl), x, y, radius (or swirl angle), r, g, b, opacity (or swirl width).
/// Walking the events backwards undoes each push until the point lands inside a drop.
[[ stitchable ]] half4 sumi(float2 pos, half4 color, float2 size, float time, float3 paper, device const float *op, int n) {
    float2 p = pos;
    // The water never sits quite still, so the rings stay soft and hand-made.
    p += float2(sin(p.y * 0.031 + time * 0.7) * 2.2 + sin(p.y * 0.11 + p.x * 0.05 + time * 0.4) * 0.9,
                cos(p.x * 0.029 - time * 0.6) * 2.2 + cos(p.x * 0.09 - p.y * 0.06 - time * 0.5) * 0.9);
    float3 acc = float3(0);
    float cover = 0.0;
    for (int i = n - 8; i >= 0; i -= 8) {
        float2 c = float2(op[i + 1], op[i + 2]);
        float a = op[i + 3];
        float2 d = p - c;
        if (op[i] < 0.5) {
            if (a <= 0.05) continue;
            float L = length(d);
            float aa = smoothstep(a + 0.9, a - 0.9, L) * op[i + 7];
            if (aa > 0.0) {
                // Ink gathers a little at the rim of each drop.
                float3 ink = float3(op[i + 4], op[i + 5], op[i + 6]);
                ink *= 1.0 - 0.14 * smoothstep(a - 7.0, a, L) * step(dot(ink, float3(0.33)), 0.8);
                acc += (1.0 - cover) * aa * ink;
                cover += (1.0 - cover) * aa;
                if (cover > 0.995) break;
            }
            p = c + d * (sqrt(max(L * L - a * a, 0.0)) / max(L, 1e-3));
        } else {
            float w = op[i + 7];
            float th = -a * exp(-dot(d, d) / (w * w));
            float cs = cos(th), sn = sin(th);
            p = c + float2(d.x * cs - d.y * sn, d.x * sn + d.y * cs);
        }
    }
    float3 col = acc + (1.0 - cover) * paper;
    // Washi fibres.
    float g = fract(sin(dot(floor(pos * 1.5), float2(12.9898, 78.233))) * 43758.5453);
    col *= 0.985 + 0.03 * g;
    return half4(half3(col), 1.0h);
}

// MARK: - Honey (drips)

static float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

/// A capsule whose radius runs from r1 at a to r2 at b.
static float roundCone(float2 p, float2 a, float2 b, float r1, float r2) {
    float2 ba = b - a;
    float l2 = dot(ba, ba);
    float2 pa = p - a;
    if (l2 < 1.0) return length(pa) - max(r1, r2);
    float rr = r1 - r2, a2 = l2 - rr * rr, il2 = 1.0 / l2;
    float y = dot(pa, ba), z = y - l2;
    float2 xv = pa * l2 - ba * y;
    float x2 = dot(xv, xv), y2 = y * y * l2, z2 = z * z * l2;
    float k = sign(rr) * rr * rr * x2;
    if (sign(z) * a2 * z2 > k) return sqrt(x2 + z2) * il2 - r2;
    if (sign(y) * a2 * y2 < k) return sqrt(x2 + y2) * il2 - r1;
    return (sqrt(x2 * a2 * il2) + y * rr) * il2 - r1;
}

/// Signed distance to the honey: a band along the top, the drips hanging from it and the
/// drops they let go (`el`, 6 floats each: ax, ay, bx, by, r1, r2), and the pool rising at
/// the bottom, dimpled where drops land (`land`, 3 floats each: x, age, size).
static float honeyField(float2 p, float time, float top, float pool, device const float *el, int en, device const float *land, int ln) {
    float yTop = top + 5.0 * sin(p.x * 0.025 + time * 0.8) + 3.0 * sin(p.x * 0.07 - time * 1.1);
    float d = p.y - yTop;
    float yPool = pool + 3.0 * sin(p.x * 0.02 - time * 0.9) + 2.0 * sin(p.x * 0.06 + time * 1.3);
    for (int i = 0; i + 2 < ln; i += 3) {
        float age = land[i + 1];
        if (age < 0) continue;
        float dx = p.x - land[i];
        float w = 12.0 + age * 45.0;
        yPool -= land[i + 2] * exp(-age * 2.2) * exp(-dx * dx / (2.0 * w * w));
    }
    d = smin(d, yPool - p.y, 10.0);
    for (int i = 0; i + 5 < en; i += 6) {
        d = smin(d, roundCone(p, float2(el[i], el[i + 1]), float2(el[i + 2], el[i + 3]), el[i + 4], el[i + 5]), 12.0);
    }
    return d;
}

static float honeyHeight(float d) { return 16.0 * sqrt(smoothstep(0.0, 24.0, -d)); }

/// Thick amber honey over whatever is drawn below: it bends what it covers, deepens in
/// colour where it is thick, catches the light along its rounded edges and casts a shadow.
[[ stitchable ]] half4 honey(float2 pos, SwiftUI::Layer layer, float2 size, float time, float top, float pool,
                            device const float *el, int en, device const float *land, int ln) {
    float d = honeyField(pos, time, top, pool, el, en, land, ln);
    float ds = honeyField(pos - float2(3, 9), time, top, pool, el, en, land, ln);
    half4 bg = layer.sample(pos);
    // The page may not reach under the status bar or home indicator: fill it with cream.
    bg.rgb += (1.0h - bg.a) * half3(0.984h, 0.945h, 0.863h);
    bg.a = 1.0h;
    bg.rgb *= half(1.0 - 0.22 * smoothstep(10.0, -6.0, ds));
    if (d > 1.0) return bg;
    float h = honeyHeight(d);
    float hx = honeyHeight(honeyField(pos + float2(1, 0), time, top, pool, el, en, land, ln)) - h;
    float hy = honeyHeight(honeyField(pos + float2(0, 1), time, top, pool, el, en, land, ln)) - h;
    float2 grad = clamp(float2(hx, hy), -3.0, 3.0);
    float3 n = normalize(float3(-grad, 1.0));
    half4 bh = layer.sample(pos - grad * 6.0);
    float3 behind = float3(bh.rgb) + (1.0 - float(bh.a)) * float3(0.984, 0.945, 0.863);
    float th = smoothstep(0.0, 40.0, -d);
    float op = 0.32 + 0.5 * th;
    float3 col = behind * float3(1.0, 0.74, 0.28) * (1.0 - op) + float3(0.80, 0.42, 0.05) * op;
    // Rim: honey is darker and redder where it thins at the edge.
    col = mix(col, float3(0.62, 0.27, 0.02), (1.0 - smoothstep(0.0, 6.0, -d)) * 0.45);
    float spec = pow(max(dot(n, normalize(float3(-0.45, -0.6, 0.66))), 0.0), 30.0);
    float glint = pow(max(dot(n, normalize(float3(0.35, 0.3, 0.89))), 0.0), 80.0);
    col += float3(1.0, 0.96, 0.82) * (spec * 0.75 + glint * 0.4);
    col += float3(1.0, 0.8, 0.4) * 0.12 * (1.0 - th);
    float a = smoothstep(1.0, -1.0, d);
    return half4(half3(mix(float3(bg.rgb), col, a)), 1.0h);
}

// MARK: - Water (swimming pool)

/// The bright web of light that a moving surface focuses onto a pool floor.
static float caustic(float2 uv, float time) {
    float2 p = uv * 6.28318 - 250.0;
    float2 i = p;
    float c = 1.0;
    const float inten = 0.005;
    for (int n = 0; n < 5; n++) {
        float t = time * (1.0 - 3.5 / float(n + 1));
        i = p + float2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
        c += 1.0 / length(float2(p.x / (sin(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
    }
    c /= 5.0;
    c = 1.17 - pow(c, 1.4);
    return clamp(pow(abs(c), 8.0), 0.0, 1.6);
}

/// Clear pool water over whatever is drawn (the floor). Rings (4 floats each: x, y, age,
/// strength) and a constant swell move the surface; the floor wobbles under it, caustics
/// dance on it, slopes pick up the pale sky and the sun glitters on the crests.
[[ stitchable ]] half4 water(float2 pos, SwiftUI::Layer layer, float2 size, float time, device const float *rip, int count, float chop) {
    float2 grad = float2(0);
    for (int i = 0; i + 3 < count; i += 4) {
        float2 c = float2(rip[i], rip[i + 1]);
        float age = rip[i + 2], amp = rip[i + 3];
        if (age < 0) continue;
        float2 dv = pos - c;
        float d = max(length(dv), 0.001);
        float x = d - age * 240.0;
        float w = 22.0 + age * 14.0;
        float env = amp * exp(-age * 1.1) * exp(-x * x / (2.0 * w * w)) / (1.0 + d / 420.0);
        grad += dv / d * env * (0.11 * cos(x * 0.11) - x / (w * w) * sin(x * 0.11));
    }
    // Swell from four directions, plus a fine chop that the hats stir up.
    const float2 D[5] = { float2(0.8, 0.6), float2(-0.5, 0.866), float2(0.95, -0.31), float2(-0.2, -0.98), float2(0.6, -0.8) };
    const float K[5] = { 0.016, 0.026, 0.043, 0.07, 0.14 };
    const float A[5] = { 5.0, 3.2, 1.6, 0.8, 0.28 };
    const float W[5] = { 1.0, 1.4, 2.0, 2.7, 4.2 };
    for (int j = 0; j < 5; j++) {
        float amp = A[j] * (j == 4 ? 0.4 + chop : 1.0);
        grad += D[j] * amp * K[j] * cos(dot(D[j], pos) * K[j] + time * W[j] + float(j) * 1.3);
    }
    float2 off = grad * 18.0;
    half4 fl = layer.sample(pos + off);
    float3 col = float3(fl.rgb) + (1.0 - float(fl.a)) * float3(0.3, 0.78, 0.88);
    // Caustics, swept along by the same waves, and only where light reaches the floor.
    float2 uv = (pos + off * 3.0) / 230.0;
    float cs = caustic(uv, time * 0.5 + 23.0) * 0.8 + caustic(uv * 1.9 + 3.1, time * 0.7 + 11.0) * 0.35;
    float lum = dot(col, float3(0.3, 0.59, 0.11));
    col += float3(0.9, 1.0, 1.0) * cs * 0.42 * smoothstep(0.25, 0.75, lum);
    // A little absorption: the water greens and deepens the floor.
    col *= float3(0.9, 0.98, 1.0);
    // Surface: the pale sky on the slopes and the sun glittering on the crests.
    float3 n = normalize(float3(-grad * 1.6, 1.0));
    float fres = clamp(1.0 - n.z, 0.0, 1.0);
    col = mix(col, float3(0.86, 0.97, 1.0), clamp(fres * 9.0, 0.0, 0.35));
    float3 h = normalize(normalize(float3(-0.35, -0.55, 1.0)) + float3(0, 0, 1));
    float glint = pow(max(dot(n, h), 0.0), 420.0) * 1.6 + pow(max(dot(n, h), 0.0), 60.0) * 0.12;
    col += float3(1.0, 1.0, 0.96) * glint;
    return half4(half3(col), 1.0h);
}
