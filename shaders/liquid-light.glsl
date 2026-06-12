// "Liquid Light" — original shader
// Procedural caustics via double domain-warped fBm.
// Shadertoy-style fragment shader: paste into https://www.shadertoy.com/new
// (expects the usual uniforms iResolution and iTime).

#define TAU 6.28318530718

// IQ cosine palette — cheap, controllable color ramps
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.00, 0.33, 0.67);
    return a + b * cos(TAU * (c * t + d));
}

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);   // smoothstep interpolation
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float amp = 0.5;
    mat2 rot = mat2(0.80, -0.60, 0.60, 0.80); // rotate each octave to hide axis bias
    for (int i = 0; i < 4; i++) {
        v += amp * noise(p);
        p = rot * p * 2.0;
        amp *= 0.5;
    }
    return v;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // centered, aspect-correct coords
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime * 0.15;

    // first warp
    vec2 q = vec2(fbm(uv + vec2(0.0, t)),
                  fbm(uv + vec2(5.2, 1.3 - t)));
    // second warp, fed by the first
    vec2 r = vec2(fbm(uv + 4.0 * q + vec2(1.7, 9.2) + 0.15 * t),
                  fbm(uv + 4.0 * q + vec2(8.3, 2.8) - 0.12 * t));
    float f = fbm(uv + 4.0 * r);

    // pull thin caustic ridges out of the warped field
    float caustic = abs(sin((f * 3.0 + length(r) * 2.0 - t * 2.0) * TAU));
    caustic = pow(caustic, 4.0);

    vec3 col = palette(f + length(q) * 0.5 + t);
    col = mix(col, vec3(1.0), caustic * 0.6);  // bright light veins
    col *= 0.6 + 0.6 * f;                       // depth shading
    col *= 1.0 - 0.3 * dot(uv, uv);             // vignette

    // --- blend into terminal background instead of overwriting it ---
    vec2 terminalUV = fragCoord / iResolution.xy;
    vec4 terminalColor = texture(iChannel0, terminalUV);
    float terminalBrightness = dot(terminalColor.rgb, vec3(0.2126, 0.7152, 0.0722));

    // full effect in dark background, fading out where text/bright pixels are
    float bgMask = 1.0 - smoothstep(0.08, 0.35, terminalBrightness);

    const float blendStrength = 0.30;
    fragColor = mix(terminalColor, vec4(col, 1.0), blendStrength * bgMask);
}
