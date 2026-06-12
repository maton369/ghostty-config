// Hot Dog Stand -- heat shimmer rising from the grill, because
// someone actually shipped this color scheme in 1992 and we're
// honoring their courage.

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    // Heat shimmer -- distort UVs more near the bottom (the grill)
    float heatIntensity = smoothstep(0.6, 0.0, uv.y);
    float wave1 = sin(uv.x * 25.0 + iTime * 3.0 + uv.y * 10.0) * 0.0015;
    float wave2 = sin(uv.x * 40.0 - iTime * 2.3 + uv.y * 15.0) * 0.0010;
    float wave3 = sin(uv.x * 15.0 + iTime * 1.7) * 0.0008;
    vec2 distort = vec2(0.0, (wave1 + wave2 + wave3) * heatIntensity);

    vec3 col = texture(iChannel0, uv + distort).rgb;
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    float darkMask = 1.0 - smoothstep(0.04, 0.20, lum);

    // Grill glow -- warm red/orange gradient rising from bottom
    vec3 grillColor = mix(
        vec3(0.60, 0.08, 0.02),
        vec3(0.40, 0.15, 0.02),
        smoothstep(0.0, 0.3, uv.y)
    );
    float grillFade = smoothstep(0.35, 0.0, uv.y);
    col += grillColor * grillFade * darkMask * 0.25;

    // Smoke wisps rising -- sparse, drifting upward
    float smokeY = uv.y - iTime * 0.06;
    float smoke = noise(vec2(uv.x * 5.0, smokeY * 3.0));
    smoke *= noise(vec2(uv.x * 9.0 + 7.0, smokeY * 6.0 - 3.0));
    smoke *= smoothstep(0.7, 0.1, uv.y);
    col += vec3(0.35, 0.18, 0.08) * smoke * 0.08;

    // Mustard splatter -- a few fixed dots that glow faintly
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        vec2 pos = vec2(
            0.15 + 0.18 * hash(vec2(fi, 1.0)),
            0.10 + 0.75 * hash(vec2(fi, 2.0))
        );
        float d = distance(uv, pos);
        float splat = smoothstep(0.025, 0.005, d);
        float pulse = 0.6 + 0.4 * sin(iTime * (0.5 + fi * 0.3) + fi * 2.0);
        col += vec3(0.50, 0.35, 0.0) * splat * pulse * darkMask * 0.15;
    }

    // Warm bloom on bright text
    vec3 bloom = vec3(0.0);
    bloom += texture(iChannel0, uv + distort + vec2( 0.0025, 0.0)).rgb;
    bloom += texture(iChannel0, uv + distort + vec2(-0.0025, 0.0)).rgb;
    bloom += texture(iChannel0, uv + distort + vec2(0.0,  0.003)).rgb;
    bloom += texture(iChannel0, uv + distort + vec2(0.0, -0.003)).rgb;
    bloom *= 0.25;
    col += bloom * 0.25 * vec3(1.0, 0.7, 0.3);

    // Vignette -- heavy, like looking into an oven
    vec2 vu = uv - 0.5;
    float vig = 1.0 - dot(vu, vu) * 0.80;
    col *= clamp(vig, 0.0, 1.0);

    // Sizzle flicker
    col *= 0.97 + 0.03 * sin(iTime * 8.0 + uv.y * 20.0);

    // Grain
    float n = hash(fragCoord.xy + fract(iTime) * 91.0);
    col += (n - 0.5) * 0.025;

    fragColor = vec4(col, 1.0);
}
