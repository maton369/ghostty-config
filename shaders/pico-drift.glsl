// Pico-8 inspired soft sunset with a tiny wandering pixel bug.
// Crisp terminal text with a gentle vertical sunset gradient tint over
// dark areas. A small pink beetle slowly crawls across dark regions of
// the screen using a tripod gait. It only renders over dark pixels so
// it never obscures terminal text. A subtle nod to bugs in the code.

float bugMask(vec2 local, float gait) {
    // Snap to pico-pixel grid for chunky 8-bit look
    vec2 p = floor(local + 0.5);

    // Body: filled ellipse, ~9 wide x 5 tall
    float bodyD = (p.x * p.x) / 18.0 + (p.y * p.y) / 5.0;
    float body = step(bodyD, 1.0);

    // Tripod gait: alternates which three legs are extended outward.
    // gait = 0 -> phase A (FR/ML/BR out); gait = 1 -> phase B (FL/MR/BL out).
    float ext  = mix(1.0, 3.0, gait); // extended-leg y offset
    float tuck = mix(3.0, 1.0, gait); // tucked-leg y offset

    float bits = 0.0;
    // Three pairs of legs (front, mid, back), one tripod active per phase.
    bits += step(distance(p, vec2( 2.0,  ext )), 0.5); // FL
    bits += step(distance(p, vec2( 2.0, -tuck)), 0.5); // FR
    bits += step(distance(p, vec2( 0.0,  tuck)), 0.5); // ML
    bits += step(distance(p, vec2( 0.0, -ext )), 0.5); // MR
    bits += step(distance(p, vec2(-2.0,  ext )), 0.5); // BL
    bits += step(distance(p, vec2(-2.0, -tuck)), 0.5); // BR

    // Antennae: two small dots in front of the head
    bits += step(distance(p, vec2(5.0,  1.0)), 0.5);
    bits += step(distance(p, vec2(5.0, -1.0)), 0.5);

    return clamp(body + bits, 0.0, 1.0);
}

// Smooth two-frequency wander in [0,1] uv space, biased to lower half.
vec2 bugPath(float t) {
    return vec2(
        0.5  + 0.40 * sin(t)             + 0.06 * sin(t * 2.7),
        0.30 + 0.20 * sin(t * 0.6 + 1.3) + 0.04 * cos(t * 1.7)
    );
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    vec3 col = texture(iChannel0, uv).rgb;

    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    float darkMask = 1.0 - smoothstep(0.04, 0.22, lum);

    // Sunset gradient: deep indigo up top, magenta middle, warm peach at horizon.
    vec3 skyTop  = vec3(0.16, 0.10, 0.32);
    vec3 skyMid  = vec3(0.52, 0.22, 0.42);
    vec3 horizon = vec3(0.98, 0.55, 0.35);

    float y = uv.y;
    vec3 sunset = mix(horizon, skyMid, smoothstep(0.0, 0.55, y));
    sunset      = mix(sunset,  skyTop, smoothstep(0.45, 1.0, y));

    // Slow breathing so the horizon glows a touch.
    float breath = 0.5 + 0.5 * sin(iTime * 0.25);
    sunset *= 0.9 + 0.15 * breath * (1.0 - smoothstep(0.0, 0.5, y));

    col += sunset * darkMask * 0.22;

    // -------- Wandering pixel bug --------
    float t = iTime * 0.12;
    vec2 bugUV     = bugPath(t);
    vec2 bugUVNext = bugPath(t + 0.05);

    // Facing direction from path derivative (pixels/time, then normalized)
    vec2 dir = normalize((bugUVNext - bugUV) * iResolution.xy + 1e-4);

    // Pixel position relative to bug center
    vec2 bugCenter = bugUV * iResolution.xy;
    vec2 rel = fragCoord.xy - bugCenter;

    // Rotate into bug-local frame so its +x always points along motion
    float ang = atan(dir.y, dir.x);
    float c = cos(-ang), s = sin(-ang);
    vec2 relRot = vec2(c * rel.x - s * rel.y, s * rel.x + c * rel.y);

    // Convert to pico-pixel units (1 pico pixel = 3 screen pixels)
    vec2 local = relRot / 3.0;

    // Gait: alternate tripods every ~0.4s
    float gait = step(0.5, fract(iTime * 2.5));

    float bug = bugMask(local, gait);

    // Only render over dark areas so text is never covered
    bug *= darkMask;

    // Pico-8 hot pink (#ff77a8), kept subtle
    vec3 bugCol = vec3(1.0, 0.467, 0.659);
    col = mix(col, bugCol, bug * 0.65);

    // Vignette
    vec2 vu = uv - 0.5;
    float vig = 1.0 - dot(vu, vu) * 0.30;
    col *= clamp(vig, 0.0, 1.0);

    fragColor = vec4(col, 1.0);
}
