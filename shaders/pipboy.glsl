// Pip-Boy CRT shader for Ghostty
// ShaderToy-compatible: uses iChannel0 = terminal output, iResolution, iTime

vec2 curve(vec2 uv) {
    uv = (uv - 0.5) * 2.0;
    uv *= 1.04;
    uv.x *= 1.0 + pow(abs(uv.y) / 5.5, 2.0);
    uv.y *= 1.0 + pow(abs(uv.x) / 4.5, 2.0);
    uv = uv * 0.5 + 0.5;
    return uv;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 cuv = curve(uv);

    // Outside curved screen = bezel black
    if (cuv.x < 0.0 || cuv.x > 1.0 || cuv.y < 0.0 || cuv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // Chromatic aberration
    float ca = 0.0009;
    vec3 col;
    col.r = texture(iChannel0, vec2(cuv.x + ca, cuv.y)).r;
    col.g = texture(iChannel0, cuv).g;
    col.b = texture(iChannel0, vec2(cuv.x - ca, cuv.y)).b;

    // Soft 5-tap blur for fuzziness
    vec3 blurCol = vec3(0.0);
    blurCol += texture(iChannel0, cuv + vec2( 0.0008,  0.0)).rgb;
    blurCol += texture(iChannel0, cuv + vec2(-0.0008,  0.0)).rgb;
    blurCol += texture(iChannel0, cuv + vec2( 0.0,     0.0010)).rgb;
    blurCol += texture(iChannel0, cuv + vec2( 0.0,    -0.0010)).rgb;
    blurCol *= 0.25;
    col = mix(col, blurCol, 0.45);

    // Phosphor tint -- bias everything toward Pip-Boy green
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 phosphor = vec3(0.18, 1.0, 0.36) * lum;
    col = mix(col, phosphor, 0.35);

    // Scanlines
    float scan = sin(cuv.y * iResolution.y * 1.6) * 0.5 + 0.5;
    col *= mix(0.82, 1.0, scan);

    // Aperture / sub-pixel grille
    float grille = sin(cuv.x * iResolution.x * 3.0) * 0.5 + 0.5;
    col *= mix(0.92, 1.0, grille);

    // Slow horizontal scroll line (television roll)
    float roll = smoothstep(0.0, 0.05, abs(fract(cuv.y - iTime * 0.08) - 0.5));
    col *= mix(0.92, 1.0, roll);

    // Flicker -- layered: fast mains hum + slow brightness wander + rare dips
    float fast = sin(iTime * 60.0) * 0.5 + 0.5;          // 60Hz mains
    float slow = sin(iTime * 2.3) * 0.5 + 0.5;           // slow wander
    float wob  = sin(iTime * 7.7 + cuv.y * 3.0) * 0.5 + 0.5;
    float flicker = mix(0.88, 1.0, fast * 0.6 + slow * 0.3 + wob * 0.1);

    // Occasional brownout dips
    float dipNoise = fract(sin(floor(iTime * 3.0) * 91.345) * 47453.21);
    float dip = step(0.92, dipNoise) * (0.25 * (1.0 - fract(iTime * 3.0)));
    flicker -= dip;

    col *= flicker;

    // Vignette
    vec2 vu = uv - 0.5;
    float vig = 1.0 - dot(vu, vu) * 0.9;
    col *= clamp(vig, 0.0, 1.0);

    // Phosphor bloom -- bright pixels glow outward
    vec3 bloom = vec3(0.0);
    bloom += texture(iChannel0, cuv + vec2( 0.003,  0.0)).rgb;
    bloom += texture(iChannel0, cuv + vec2(-0.003,  0.0)).rgb;
    bloom += texture(iChannel0, cuv + vec2( 0.0,    0.003)).rgb;
    bloom += texture(iChannel0, cuv + vec2( 0.0,   -0.003)).rgb;
    bloom *= 0.25;
    col += bloom * 0.35 * vec3(0.18, 1.0, 0.36);

    // Slight noise grain
    float n = fract(sin(dot(fragCoord.xy + iTime, vec2(12.9898, 78.233))) * 43758.5453);
    col += (n - 0.5) * 0.025;

    fragColor = vec4(col, 1.0);
}
