// Eye cursor tracker shader for Ghostty
// Smooth eye movement with periodic blinks

// Play with this value to change the size of the eye
#define EYE_SCALE_FACTOR 1.0

#define EYE_CENTER vec2(0.93, 0.5)
#define EYE_WIDTH 0.025 * EYE_SCALE_FACTOR
#define EYE_HEIGHT 0.015 * EYE_SCALE_FACTOR
#define IRIS_RADIUS 0.009 * EYE_SCALE_FACTOR
#define PUPIL_RADIUS 0.0045 * EYE_SCALE_FACTOR
#define IRIS_COLOR vec4(0.2, 0.5, 1.0, 1.0)
#define PUPIL_COLOR vec4(0.05, 0.05, 0.05, 1.0)
#define SCLERA_COLOR vec4(0.95, 0.95, 0.95, 1.0)
#define OUTLINE_COLOR vec4(0.1, 0.1, 0.1, 1.0)
#define OUTLINE_THICKNESS 0.003

// Play with these to change the eye movement behaviour
#define IRIS_TRAVEL 0.6
#define MOVE_DURATION 0.4
#define BLINK_INTERVAL 10.0
#define BLINK_DURATION 0.36

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    fragColor = texture(iChannel0, uv);

    float aspect = iResolution.x / iResolution.y;

    vec2 currPos = iCurrentCursor.xy / iResolution.xy;
    vec2 currSize = iCurrentCursor.zw / iResolution.xy;
    vec2 cursorCenter = currPos + currSize * vec2(0.5, -0.5);

    vec2 prevPos = iPreviousCursor.xy / iResolution.xy;
    vec2 prevSize = iPreviousCursor.zw / iResolution.xy;
    vec2 prevCenter = prevPos + prevSize * vec2(0.5, -0.5);

    float elapsed = clamp((iTime - iTimeCursorChange) / MOVE_DURATION, 0.0, 1.0);
    float t = elapsed * elapsed * (3.0 - 2.0 * elapsed);

    float prevNormY = clamp((prevCenter.y - 0.5) * 2.0, -1.0, 1.0);
    float currNormY = clamp((cursorCenter.y - 0.5) * 2.0, -1.0, 1.0);
    float normY = mix(prevNormY, currNormY, t);

    float cycle = mod(iTime, BLINK_INTERVAL);
    float blink = 1.0;
    if (cycle < BLINK_DURATION) {
        float x = cycle / (BLINK_DURATION * 0.5);
        x = x < 1.0 ? x : 2.0 - x;
        blink = x;
    }

    float openHeight = EYE_HEIGHT * blink;

    vec2 irisCenter = EYE_CENTER + vec2(-0.008, normY * openHeight * IRIS_TRAVEL);
    vec2 p = vec2((uv.x - EYE_CENTER.x) * aspect, uv.y - EYE_CENTER.y);

    float eyelidMask = abs(p.y) - openHeight * (1.0 - pow(abs(p.x / (EYE_WIDTH * aspect)), 1.5));
    bool insideEye = eyelidMask < 0.0 && abs(p.x) < EYE_WIDTH * aspect;

    vec2 pIris = vec2((uv.x - irisCenter.x) * aspect, uv.y - irisCenter.y);
    float distIris = length(pIris);
    float distPupil = length(pIris);

    float outlineDist = abs(eyelidMask);
    float outline = smoothstep(OUTLINE_THICKNESS, 0.0, outlineDist) * float(abs(p.x) < EYE_WIDTH * aspect + OUTLINE_THICKNESS);

    if (insideEye) {
        fragColor = SCLERA_COLOR;
        fragColor = mix(fragColor, IRIS_COLOR, smoothstep(IRIS_RADIUS, IRIS_RADIUS * 0.85, distIris));
        fragColor = mix(fragColor, PUPIL_COLOR, smoothstep(PUPIL_RADIUS, PUPIL_RADIUS * 0.7, distPupil));
    }

    fragColor = mix(fragColor, OUTLINE_COLOR, outline);
}

