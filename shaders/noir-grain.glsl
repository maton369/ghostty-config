// Noir -- film grain, venetian blind shadows creeping across the wall,
// a single amber desk lamp, and the occasional flicker of a projector
// that's seen better days.

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float hash1(float n) {
    return fract(sin(n) * 43758.5453);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    vec3 col = texture(iChannel0, uv).rgb;
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    float darkMask = 1.0 - smoothstep(0.04, 0.20, lum);

    // Desaturate toward silver -- noir is almost monochrome
    vec3 gray = vec3(lum);
    col = mix(col, gray, 0.55);

    // Amber desk lamp -- warm cone of light from upper-right
    vec2 lampPos = vec2(0.85, 0.90);
    float lampDist = distance(uv, lampPos);
    float lampCone = smoothstep(0.70, 0.10, lampDist);
    float lampAngle = atan(uv.y - lampPos.y, uv.x - lampPos.x);
    lampCone *= smoothstep(-2.5, -1.2, lampAngle) * smoothstep(-0.3, -1.0, lampAngle);
    vec3 amber = vec3(0.85, 0.60, 0.25);
    col += amber * lampCone * darkMask * 0.08;
    col += amber * smoothstep(0.50, 0.05, lampDist) * darkMask * 0.04;

    // Venetian blind shadows -- diagonal bars slowly rotating
    float blindAngle = iTime * 0.015;
    float blindCoord = uv.x * cos(blindAngle) + uv.y * sin(blindAngle);
    float blinds = smoothstep(0.42, 0.50, fract(blindCoord * 8.0));
    float blindStrength = 0.12 * smoothstep(0.3, 0.7, uv.x);
    col *= 1.0 - blinds * blindStrength * darkMask;

    // Smoke trail -- a single wisp of cigarette smoke
    float smokeX = 0.25 + 0.08 * sin(iTime * 0.2);
    float smokeDist = abs(uv.x - smokeX - 0.02 * sin(uv.y * 8.0 + iTime * 0.5));
    float smokeTrail = smoothstep(0.03, 0.0, smokeDist);
    smokeTrail *= smoothstep(0.2, 0.8, uv.y);
    smokeTrail *= smoothstep(1.0, 0.85, uv.y);
    col += vec3(0.25, 0.23, 0.22) * smokeTrail * darkMask * 0.12;

    // Projector flicker -- occasional brightness dip
    float flickSeg = floor(iTime * 3.0);
    float flick = 1.0 - 0.06 * step(0.90, hash1(flickSeg + 7.0));
    col *= flick;

    // Heavy film grain
    float grain = hash(fragCoord.xy + fract(iTime) * 91.0) - 0.5;
    col += grain * 0.045;

    // Vignette -- deep and moody
    vec2 vu = uv - 0.5;
    float vig = 1.0 - dot(vu, vu) * 1.0;
    col *= clamp(vig, 0.0, 1.0);

    // Faint scanlines -- like watching on an old monitor
    float scan = sin(uv.y * iResolution.y * 1.5) * 0.5 + 0.5;
    col *= mix(0.95, 1.0, scan);

    fragColor = vec4(col, 1.0);
}
