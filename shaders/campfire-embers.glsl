// Campfire -- floating embers rise into the night sky, firelight
// flickers across the terminal, and somewhere a coyote howls at
// nobody in particular.

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
    float darkMask = 1.0 - smoothstep(0.04, 0.20, lum);

    // Firelight flicker -- warm light that breathes unevenly
    float flicker = 0.0;
    flicker += sin(iTime * 3.7) * 0.3;
    flicker += sin(iTime * 7.1 + 1.0) * 0.15;
    flicker += sin(iTime * 11.3 + 3.0) * 0.08;
    flicker = 0.92 + flicker * 0.08;

    // Warm fire glow from bottom-center
    vec2 firePos = vec2(0.5, -0.1);
    float fireDist = distance(uv, firePos);
    float fireGlow = smoothstep(0.9, 0.1, fireDist);
    vec3 fireColor = mix(
        vec3(0.80, 0.25, 0.05),
        vec3(0.50, 0.15, 0.02),
        smoothstep(0.1, 0.7, fireDist)
    );
    col += fireColor * fireGlow * darkMask * 0.12 * flicker;

    // Rising embers -- particles floating upward with drift
    for (int i = 0; i < 30; i++) {
        float fi = float(i);
        float seed1 = hash(vec2(fi, 10.0));
        float seed2 = hash(vec2(fi, 20.0));
        float seed3 = hash(vec2(fi, 30.0));

        float speed = 0.04 + seed1 * 0.06;
        float life = fract(seed2 * 13.7 + iTime * speed);

        // Start near bottom-center, drift outward as they rise
        float startX = 0.35 + seed1 * 0.30;
        float drift = sin(life * 6.28 + fi * 2.0) * (0.05 + seed3 * 0.08);

        vec2 pos = vec2(
            startX + drift * life,
            life
        );

        float d = distance(uv, pos);

        // Ember size shrinks as it rises and cools
        float size = mix(0.006, 0.002, life);
        float ember = smoothstep(size, size * 0.3, d);

        // Color cools from bright orange-yellow to dim red
        vec3 emberCol = mix(
            vec3(1.0, 0.6, 0.1),
            vec3(0.6, 0.1, 0.0),
            life
        );

        // Fade out near top
        float fade = 1.0 - smoothstep(0.7, 1.0, life);
        // Flicker individual embers
        float sparkle = 0.5 + 0.5 * sin(iTime * (8.0 + seed3 * 12.0) + fi * 3.0);

        col += emberCol * ember * fade * sparkle * darkMask * 0.5;
    }

    // Starfield above the treeline
    float starZone = smoothstep(0.5, 0.9, uv.y);
    float starGrid = 60.0;
    vec2 starCell = floor(uv * starGrid);
    float starVal = hash(starCell);
    float isStar = step(0.95, starVal) * starZone;
    float twinkle = 0.4 + 0.6 * sin(iTime * (1.5 + starVal * 3.0) + starVal * 40.0);
    vec2 starLocal = fract(uv * starGrid) - 0.5;
    float starDot = smoothstep(0.10, 0.0, length(starLocal));
    col += vec3(0.9, 0.85, 0.7) * starDot * isStar * twinkle * darkMask * 0.3;

    // Apply firelight flicker to whole scene
    col *= flicker;

    // Warm bloom
    vec3 bloom = vec3(0.0);
    bloom += texture(iChannel0, uv + vec2( 0.0022, 0.0)).rgb;
    bloom += texture(iChannel0, uv + vec2(-0.0022, 0.0)).rgb;
    bloom += texture(iChannel0, uv + vec2(0.0,  0.0025)).rgb;
    bloom += texture(iChannel0, uv + vec2(0.0, -0.0025)).rgb;
    bloom *= 0.25;
    col += bloom * 0.20 * vec3(1.0, 0.6, 0.3);

    // Smoky vignette -- heavier at top corners
    vec2 vu = uv - 0.5;
    float vig = 1.0 - dot(vu, vu) * 0.70;
    col *= clamp(vig, 0.0, 1.0);

    // Grain
    float n = hash(fragCoord.xy + fract(iTime) * 91.0);
    col += (n - 0.5) * 0.022;

    fragColor = vec4(col, 1.0);
}
