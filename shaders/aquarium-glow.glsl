// Aquarium -- bioluminescent particles drift through deep water,
// caustic light ripples dance on the glass, and the reef glows
// softly behind your code.

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

    vec3 col = texture(iChannel0, uv).rgb;
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    float darkMask = 1.0 - smoothstep(0.03, 0.18, lum);

    // Caustic light ripples -- overlapping sine waves
    float c1 = sin(uv.x * 12.0 + uv.y *  5.0 + iTime * 0.4);
    float c2 = sin(uv.x *  8.0 - uv.y * 10.0 + iTime * 0.3 + 2.0);
    float c3 = sin(uv.x * 15.0 + uv.y *  8.0 - iTime * 0.5 + 5.0);
    float caustic = (c1 + c2 + c3) / 3.0;
    caustic = smoothstep(0.3, 0.8, caustic);

    vec3 causticColor = mix(
        vec3(0.05, 0.25, 0.40),
        vec3(0.10, 0.50, 0.55),
        caustic
    );
    col += causticColor * caustic * darkMask * 0.08;

    // Bioluminescent particles -- floating plankton
    for (int i = 0; i < 20; i++) {
        float fi = float(i);
        float seed1 = hash(vec2(fi, 0.0));
        float seed2 = hash(vec2(fi, 1.0));
        float seed3 = hash(vec2(fi, 2.0));

        float speed = 0.02 + seed1 * 0.03;
        float drift = sin(iTime * (0.3 + seed2 * 0.4) + fi * 3.0) * 0.05;

        vec2 pos = vec2(
            fract(seed1 * 7.3 + drift + iTime * seed3 * 0.01),
            fract(seed2 * 5.7 + iTime * speed)
        );

        float d = distance(uv, pos);
        float glow = smoothstep(0.020, 0.002, d);
        float pulse = 0.5 + 0.5 * sin(iTime * (1.0 + seed3 * 2.0) + fi * 5.0);

        vec3 planktonCol = mix(
            vec3(0.1, 0.5, 0.8),
            vec3(0.6, 0.2, 0.7),
            seed3
        );
        // Occasional jellyfish pink
        planktonCol = mix(planktonCol, vec3(0.8, 0.3, 0.5), step(0.85, seed2));

        col += planktonCol * glow * pulse * darkMask * 0.35;
    }

    // Deep water gradient -- darker at bottom, faint blue-green at top
    vec3 deepBlue = vec3(0.02, 0.06, 0.12);
    vec3 shallowBlue = vec3(0.04, 0.12, 0.18);
    vec3 waterGrad = mix(deepBlue, shallowBlue, uv.y);
    col += waterGrad * darkMask * 0.15;

    // Soft underwater bloom
    vec3 bloom = vec3(0.0);
    bloom += texture(iChannel0, uv + vec2( 0.0022, 0.0)).rgb;
    bloom += texture(iChannel0, uv + vec2(-0.0022, 0.0)).rgb;
    bloom += texture(iChannel0, uv + vec2(0.0,  0.0028)).rgb;
    bloom += texture(iChannel0, uv + vec2(0.0, -0.0028)).rgb;
    bloom *= 0.25;
    col += bloom * 0.20 * vec3(0.2, 0.6, 0.8);

    // Very subtle current sway
    col = texture(iChannel0, uv + vec2(
        sin(uv.y * 6.0 + iTime * 0.5) * 0.0004,
        0.0
    )).rgb * 0.15 + col * 0.85;

    // Vignette -- like peering into a tank
    vec2 vu = uv - 0.5;
    float vig = 1.0 - dot(vu, vu) * 0.65;
    col *= clamp(vig, 0.0, 1.0);

    // Faint grain
    float n = hash(fragCoord.xy + fract(iTime) * 91.0);
    col += (n - 0.5) * 0.015;

    fragColor = vec4(col, 1.0);
}
