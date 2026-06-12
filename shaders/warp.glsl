warp — domain-warped fluid background for Ghostty
//
// FluidBackground.metal (IQ double-warp FBM).
// Cycles through 4 colour palettes over 1 hour for ambient time awareness:
//   0–15 min  Violet   (indigo → purple → lavender)
//  15–30 min  Aurora   (teal → emerald → cyan)
//  30–45 min  Ember    (maroon → crimson → amber)
//  45–60 min  Midnight (navy → cobalt → ice blue)
// Dark terminal background areas are replaced with the fluid field;
// text/bright content is preserved. Animation slows when unfocused.

// ── Noise primitives ─────────────────────────────────────────────────────────

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm4(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * valueNoise(p);
        p *= 2.02;
        a *= 0.5;
    }
    return v;
}

// ── Main ──────────────────────────────────────────────────────────────────────

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    vec4 term = texture(iChannel0, uv);

    // Aspect-correct UV for the warp field
    vec2 wuv = uv;
    wuv.x *= iResolution.x / iResolution.y;

    // Slow to 15% when unfocused
    float speed = iFocus > 0 ? 0.5 : 0.15;
    float t = iTime * 0.08 * 0.5 * speed;

    const float WARP = 3.5;

    // IQ double-warp: q warps with uv, r warps with q
    vec2 q = vec2(
        fbm4(wuv * 1.2 + vec2(0.0,  t)),
        fbm4(wuv * 1.2 + vec2(5.2, -t * 0.8))
    );
    vec2 r = vec2(
        fbm4(wuv * 1.6 + WARP * q + vec2(1.7, 9.2) + t * 0.40),
        fbm4(wuv * 1.6 + WARP * q + vec2(8.3, 2.8) + t * 0.35)
    );

    float f = fbm4(wuv * 1.1 + (WARP + 0.3) * r);
    f = smoothstep(0.15, 0.95, f);

    // ── Hourly palette cycle ──────────────────────────────────────────────────
    vec3 palDeep[4] = vec3[4](
        vec3(0.04, 0.04, 0.10),   // Violet:   dark indigo
        vec3(0.02, 0.08, 0.08),   // Aurora:   dark teal
        vec3(0.10, 0.03, 0.02),   // Ember:    dark maroon
        vec3(0.02, 0.03, 0.10)    // Midnight: dark navy
    );
    vec3 palMid[4] = vec3[4](
        vec3(0.20, 0.12, 0.38),   // Violet:   deep purple
        vec3(0.05, 0.28, 0.25),   // Aurora:   emerald
        vec3(0.38, 0.12, 0.08),   // Ember:    deep crimson
        vec3(0.06, 0.12, 0.35)    // Midnight: cobalt
    );
    vec3 palHigh[4] = vec3[4](
        vec3(0.68, 0.55, 0.96),   // Violet:   lavender
        vec3(0.30, 0.90, 0.80),   // Aurora:   cyan/mint
        vec3(0.95, 0.55, 0.25),   // Ember:    amber/coral
        vec3(0.35, 0.65, 0.95)    // Midnight: ice blue
    );

    float cycle = mod(iTime, 3600.0) / 3600.0;
    float t4    = cycle * 4.0;
    int   i0    = int(floor(t4)) % 4;
    int   i1    = (i0 + 1) % 4;
    float blend = smoothstep(0.0, 1.0, fract(t4));

    vec3 deep = mix(palDeep[i0], palDeep[i1], blend);
    vec3 mid  = mix(palMid[i0],  palMid[i1],  blend);
    vec3 high = mix(palHigh[i0], palHigh[i1], blend);
    // ─────────────────────────────────────────────────────────────────────────

    vec3 warp = mix(deep, mid, smoothstep(0.0, 0.6, f));
    warp      = mix(warp, high, smoothstep(0.72, 1.0, f));

    // Drifting specular sheen
    float sheen = smoothstep(0.82, 1.0, fbm4(wuv * 0.7 + vec2(t * 0.6)));
    warp += sheen * 0.12 * high;

    // Breathing vignette
    vec2  centred = uv - 0.5;
    float breath  = 0.85 + 0.08 * sin(iTime * 0.18 * speed);
    warp *= mix(1.0, breath, smoothstep(0.08, 0.9, dot(centred, centred) * 2.2));

    // Blend: warp into dark background areas, preserve bright text
    float luma  = dot(term.rgb, vec3(0.2126, 0.7152, 0.0722));
    float alpha = 1.0 - smoothstep(0.04, 0.22, luma);

    vec3 col = mix(term.rgb, warp, alpha * 0.92);
    fragColor = vec4(col, term.a);
}
