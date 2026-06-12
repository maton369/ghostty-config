// Cyberpunk -- soft synthwave horizon, gentle scanlines, faint chromatic
// aberration, a rare glitch tear, and a wandering pixel bug crawling
// behind the terminal text. The bug (cyan body, hot-pink legs and
// antennae) only renders over dark pixels so it never obscures glyphs.

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float hash1(float n) {
    return fract(sin(n) * 43758.5453);
}

float bugMask(vec2 local, float gait) {
    vec2 p = floor(local + 0.5);

    float bodyD = (p.x * p.x) / 18.0 + (p.y * p.y) / 5.0;
    float body = step(bodyD, 1.0);

    float ext  = mix(1.0, 3.0, gait);
    float tuck = mix(3.0, 1.0, gait);

    float bits = 0.0;
    bits += step(distance(p, vec2( 2.0,  ext )), 0.5);
    bits += step(distance(p, vec2( 2.0, -tuck)), 0.5);
    bits += step(distance(p, vec2( 0.0,  tuck)), 0.5);
    bits += step(distance(p, vec2( 0.0, -ext )), 0.5);
    bits += step(distance(p, vec2(-2.0,  ext )), 0.5);
    bits += step(distance(p, vec2(-2.0, -tuck)), 0.5);

    bits += step(distance(p, vec2(5.0,  1.0)), 0.5);
    bits += step(distance(p, vec2(5.0, -1.0)), 0.5);

    return clamp(body + bits, 0.0, 1.0);
}

float bugBodyMask(vec2 local) {
    vec2 p = floor(local + 0.5);
    float bodyD = (p.x * p.x) / 18.0 + (p.y * p.y) / 5.0;
    return step(bodyD, 1.0);
}

vec2 bugPath(float t) {
    return vec2(
        0.5  + 0.40 * sin(t)             + 0.06 * sin(t * 2.7),
        0.30 + 0.20 * sin(t * 0.6 + 1.3) + 0.04 * cos(t * 1.7)
    );
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    // Subtle VHS wobble on the text sample coords.
    float wobble = sin(uv.y * 220.0 + iTime * 2.1) * 0.0005
                 + sin(uv.y *  19.0 + iTime * 0.8) * 0.0010;
    vec2 uvText = uv;
    uvText.x += wobble;

    // Glitch tear -- a horizontal band slips sideways at random.
    float gSeg  = floor(iTime * 1.4);
    float gY    = hash1(gSeg);
    float gFire = step(0.93, hash1(gSeg + 7.3));
    float gBand = smoothstep(0.012, 0.0, abs(uv.y - gY));
    uvText.x += gBand * gFire * (hash1(gSeg + 13.1) - 0.5) * 0.050;

    // Faint chromatic aberration -- breathing magenta/cyan channel split.
    float ca = 0.0010 + 0.0006 * sin(iTime * 0.55);
    float r = texture(iChannel0, uvText + vec2(ca, 0.0)).r;
    float g = texture(iChannel0, uvText).g;
    float b = texture(iChannel0, uvText - vec2(ca, 0.0)).b;
    vec3 col = vec3(r, g, b);

    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    float darkMask = 1.0 - smoothstep(0.04, 0.22, lum);

    // -------- Synthwave horizon: hot-pink glow at horizon, indigo up top --------
    vec3 skyTop  = vec3(0.04, 0.02, 0.18);
    vec3 skyMid  = vec3(0.36, 0.05, 0.42);
    vec3 horizon = vec3(1.00, 0.16, 0.43);
    float y = uv.y;
    vec3 sunset = mix(horizon, skyMid, smoothstep(0.0, 0.45, y));
    sunset      = mix(sunset,  skyTop, smoothstep(0.40, 1.0, y));
    float breath = 0.5 + 0.5 * sin(iTime * 0.25);
    sunset *= 0.85 + 0.20 * breath * (1.0 - smoothstep(0.0, 0.45, y));
    col += sunset * darkMask * 0.18;

    // -------- Wandering pixel bug --------
    float t = iTime * 0.12;
    vec2 bugUV     = bugPath(t);
    vec2 bugUVNext = bugPath(t + 0.05);
    vec2 dir = normalize((bugUVNext - bugUV) * iResolution.xy + 1e-4);

    vec2 bugCenter = bugUV * iResolution.xy;
    vec2 rel = fragCoord.xy - bugCenter;
    float ang = atan(dir.y, dir.x);
    float c = cos(-ang), s = sin(-ang);
    vec2 relRot = vec2(c * rel.x - s * rel.y, s * rel.x + c * rel.y);

    vec2 local = relRot / 3.0;
    float gait = step(0.5, fract(iTime * 2.5));

    float bug     = bugMask(local, gait);
    float bugBody = bugBodyMask(local);
    float bugLegs = clamp(bug - bugBody, 0.0, 1.0);
    bug     *= darkMask;
    bugBody *= darkMask;
    bugLegs *= darkMask;

    vec3 bodyCol = vec3(0.02, 0.85, 0.91); // electric cyan
    vec3 legCol  = vec3(1.00, 0.16, 0.43); // hot pink
    col = mix(col, bodyCol, bugBody * 0.75);
    col = mix(col, legCol,  bugLegs * 0.85);

    // -------- Random glitch datamosh blocks --------
    // Chunk time into short segments; each segment may fire a small
    // displaced + neon-tinted rectangle of terminal content. Three
    // independent streams so several can flicker at once.
    for (int i = 0; i < 3; i++) {
        float salt = float(i) * 117.0;
        float seg  = floor(iTime * 7.0 + salt);
        float fire = step(0.84, hash1(seg + 41.0 + salt));

        float bx = hash1(seg + 11.0 + salt);
        float by = hash1(seg + 17.0 + salt);
        float bw = 0.03 + 0.16 * hash1(seg + 23.0 + salt);
        float bh = 0.008 + 0.040 * hash1(seg + 29.0 + salt);

        float inX = step(bx, uv.x) * step(uv.x, bx + bw);
        float inY = step(by, uv.y) * step(uv.y, by + bh);
        float inBox = inX * inY * fire;

        float disp = (hash1(seg + 31.0 + salt) - 0.5) * 0.05;
        vec3 glitchSample = texture(iChannel0, vec2(uvText.x + disp, uvText.y)).rgb;
        vec3 glitchTint = mix(
            vec3(1.00, 0.16, 0.43),
            vec3(0.02, 0.85, 0.91),
            step(0.5, hash1(seg + 37.0 + salt))
        );
        glitchSample = mix(glitchSample, glitchTint, 0.40);
        col = mix(col, glitchSample, inBox);
    }

    // Occasional hard RGB-split band -- whole row briefly shears into channels.
    float bSeg  = floor(iTime * 2.5);
    float bFire = step(0.92, hash1(bSeg + 51.0));
    float bandY = hash1(bSeg + 53.0);
    float bandH = 0.005 + 0.020 * hash1(bSeg + 59.0);
    float inBand = smoothstep(bandH, 0.0, abs(uv.y - bandY)) * bFire;
    float hardCa = 0.010 * inBand;
    vec3 hardSplit = vec3(
        texture(iChannel0, uvText + vec2(hardCa, 0.0)).r,
        texture(iChannel0, uvText).g,
        texture(iChannel0, uvText - vec2(hardCa, 0.0)).b
    );
    col = mix(col, hardSplit, inBand);

    // -------- Neon bloom on bright pixels (text glow) --------
    float bloom = smoothstep(0.55, 1.0, lum);
    col += col * bloom * 0.22;

    // -------- CRT scanlines (very subtle) --------
    float scan = 0.94 + 0.06 * sin(fragCoord.y * 3.14159);
    col *= scan;

    // -------- Subtle grain --------
    float grain = hash(fragCoord + fract(iTime) * 91.0) - 0.5;
    col += grain * 0.03;

    // -------- Vignette --------
    vec2 vu = uv - 0.5;
    float vig = 1.0 - dot(vu, vu) * 0.55;
    col *= clamp(vig, 0.0, 1.0);

    // -------- App frame border --------
    // Thin neon outline + soft inner glow so the terminal reads as an app,
    // not text spilling onto the desktop. Drawn after vignette so the
    // frame stays bright at the corners.
    {
        float dL = fragCoord.x;
        float dR = iResolution.x - fragCoord.x;
        float dT = iResolution.y - fragCoord.y;
        float dB = fragCoord.y;
        float minEdge = min(min(dL, dR), min(dT, dB));

        // Thin cyan line ~2 pixels in from the edge.
        float line = smoothstep(1.2, 0.2, abs(minEdge - 2.0));
        // Soft inner glow falling off over ~12 pixels.
        float glow = max(smoothstep(12.0, 3.0, minEdge) - line, 0.0);

        vec3 frameCol = vec3(0.02, 0.85, 0.91);
        col = mix(col, frameCol, line * 0.85);
        col += frameCol * glow * 0.08;
    }

    fragColor = vec4(col, 1.0);
}
