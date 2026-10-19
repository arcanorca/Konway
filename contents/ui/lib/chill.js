.pragma library

// Pure helpers behind Chill mode. Kept free of QML types so they can be tested with node.

function clamp(v, lo, hi) {
    return Math.max(lo, Math.min(hi, v));
}

// Slow sinusoidal "breathing" of the simulation tempo around 1.0.
function tempoMultiplier(nowMs, strength, periodSec) {
    const s = clamp(Number(strength), 0, 0.8);
    const period = Math.max(10, Number(periodSec));
    const phase = (nowMs / 1000.0) / period * Math.PI * 2.0;
    return clamp(1.0 + s * Math.sin(phase), 0.2, 2.0);
}

// Fraction (0..1) of the evening dim to apply at a local time.
// Dimming ramps in over `rampMinutes` after startHour and out before endHour.
function dimFraction(hour, minute, startHour, endHour, rampMinutes) {
    const start = clamp(Math.round(Number(startHour)), 0, 23) * 60;
    const end = clamp(Math.round(Number(endHour)), 0, 23) * 60;
    if (start === end) {
        return 0.0;
    }
    const ramp = Math.max(1, Number(rampMinutes));
    const now = clamp(Number(hour), 0, 23) * 60 + clamp(Number(minute), 0, 59);

    const span = (end - start + 1440) % 1440;
    const elapsed = (now - start + 1440) % 1440;
    if (elapsed >= span) {
        return 0.0;
    }
    const intoRamp = Math.min(1.0, elapsed / ramp);
    const outOfRamp = Math.min(1.0, (span - elapsed) / ramp);
    const t = Math.min(intoRamp, outOfRamp);
    // Smoothstep so brightness changes feel natural.
    return t * t * (3.0 - 2.0 * t);
}
