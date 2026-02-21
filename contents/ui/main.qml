import QtQuick
import QtQuick.Window
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import "../patterns/patternData.js" as PatternData
import "lib/mainConstants.js" as MainConstants

WallpaperItem {
    id: root

    readonly property var paletteDefaults: MainConstants.paletteDefaults
    readonly property var coreCuratedIds: MainConstants.coreCuratedIds
    readonly property string builtinGosperRle: MainConstants.builtinGosperRle
    readonly property var clockGlyphs: MainConstants.clockGlyphs
    readonly property var miniClockGlyphs: MainConstants.miniClockGlyphs
    readonly property var defaultCategoryWeights: MainConstants.defaultCategoryWeights

    property var patternCatalog: []
    property var patternById: ({})
    property var parsedRleCache: ({})
    property var builtinPatternCache: ({})

    property bool simulationInitialized: false
    property bool currentStateIsA: true
    property bool stampActive: false
    property bool stampClearPending: false
    property int stampHoldSteps: 0
    property bool killActive: false
    property bool killClearPending: false
    property int killHoldSteps: 0
    property bool pendingStartupSeed: false
    property bool startupScatterDone: false
    property bool startupGosperInjected: false
    property int startupForceSeedSteps: 0
    property int startupWarmupSteps: 0
    property int startupHealthChecksRemaining: 0
    property bool pendingResetRequested: false
    property string pendingResetReason: ""

    property real randomSeed: Math.random() * 100000.0
    property int generation: 0
    property int inactivityCounter: 0
    property int stepsSincePatternInjection: 0
    property int rescueCooldownSteps: 0

    property bool seedModeA: false
    property bool seedModeB: false
    property bool applyStampA: false
    property bool applyStampB: false
    property bool applyKillA: false
    property bool applyKillB: false

    property bool clockRegionValid: false
    property int clockRegionX: 0
    property int clockRegionY: 0
    property int clockRegionW: 0
    property int clockRegionH: 0
    property int clockLastMinuteToken: -1
    property string clockLastText: ""
    property var clockCurrentCells: []
    property var clockPreviousCells: []
    property var clockNextCells: []
    property var clockRenderCells: []
    property int clockTransitionStep: 0
    property int clockTransitionTotalSteps: 6
    property int clockBarrierPadding: Math.max(1, Math.min(8, Math.round(2 * cfgClockScale)))
    property int clockBarrierThickness: Math.max(1, Math.round(cfgClockScale))

    property string lastPreviewSeedRequest: ""
    property string lastReseedRequest: ""

    property bool cfgEnabled: cfgBool("enabled", true)
    property string cfgPreset: cfgString("preset", "Balanced")
    property bool cfgDebug: cfgBool("debugLogging", false)
    property string cfgReseedRequest: cfgString("reseedRequest", "")
    property string cfgClockMode: cfgString("clockMode", "Off")
    property real cfgClockScale: cfgReal("clockScale", 1.0, 0.35, 2.0)

    property int cfgCellSize: cfgInt("cellSize", 10, 2, 64)
    property int cfgTps: cfgInt("tps", 3, 1, 240)
    property int cfgStepsPerFrame: cfgInt("stepsPerFrame", 1, 1, 8)
    property bool cfgWrapEdges: cfgBool("wrapEdges", true)
    property string cfgRuleString: cfgString("ruleString", "B3/S23")
    // Startup seeding intensity dial (0.05..1.00). Mapped to effective alive-cell coverage.
    property real cfgInitialDensity: cfgReal("initialDensity", 0.50, 0.05, 1.00)
    property real startupSeedIntensity: Math.max(0.05, Math.min(1.00, cfgInitialDensity))
    property real startupFixedDensity: startupCoverageFromIntensity(startupSeedIntensity)
    property real bootstrapSeedDensity: {
        return startupFixedDensity;
    }

    property bool cfgAutoInject: cfgBool("autoInject", true)
    property int cfgInjectIntervalMs: cfgInt("injectIntervalMs", 2000, 500, 120000)
    property real cfgMinAliveRatio: cfgReal("minAliveRatio", 0.20, 0.01, 0.95)
    property real cfgRarePatternChance: cfgReal("rarePatternChance", 0.10, 0.0, 1.0)
    property real cfgForcedInjectChance: cfgReal("forcedInjectChance", 0.10, 0.0, 1.0)

    property string cfgInjectorMode: cfgString("injectorMode", "Mixed")
    property string cfgCategoryWeights: cfgString("categoryWeights", "{\"gliders\":1.1,\"spaceships\":1.0,\"methuselahs\":0.8,\"oscillators\":0.6,\"guns\":0.12,\"still_lifes\":0.25}")
    property string cfgEnabledCategories: cfgString("enabledCategories", "gliders,spaceships,methuselahs,oscillators,guns,still_lifes")
    property int cfgMaxPatternSize: cfgInt("maxPatternSize", 96, 8, 4096)
    property bool cfgAllowLargePatterns: cfgBool("allowLargePatterns", false)
    property string cfgPreviewPatternId: cfgString("previewPatternId", "glider")
    property string cfgPreviewSeedRequest: cfgString("previewSeedRequest", "")
    property bool cfgCursorDrawEnabled: cfgBool("cursorDrawEnabled", true)
    property int cfgCursorBrushSize: cfgInt("cursorBrushSize", 2, 1, 12)

    property string cfgPalette: cfgString("palette", "Calm Dark")
    property color cfgAliveColor: cfgColor("aliveColor", paletteColor("alive"))
    property color cfgDeadColor: cfgColor("deadColor", paletteColor("dead"))
    property color cfgBackgroundColor: cfgColor("backgroundColor", paletteColor("bg"))
    property string cfgCellShape: cfgString("cellShape", "Go Board")
    property bool cfgDyingFadeEnabled: cfgBool("dyingFadeEnabled", true)
    property int cfgDyingFadeTicks: cfgInt("dyingFadeTicks", 1, 1, 8)

    property bool cfgPhotoSafe: cfgBool("photosensitiveSafe", false)
    property real cfgSafeContrast: cfgReal("safeContrast", 0.78, 0.4, 1.0)
    property real cfgSafeSaturation: cfgReal("safeSaturation", 0.50, 0.0, 1.0)
    property bool cfgSafeUltraLowTpsEnabled: cfgBool("safeUltraLowTpsEnabled", false)
    property real cfgSafeUltraLowTps: cfgReal("safeUltraLowTps", 0.5, 0.1, 0.99)

    property int cfgSimDownscale: cfgInt("simDownscale", 1, 1, 12)
    property bool cfgSyncFpsWithTps: cfgBool("syncFpsWithTps", true)
    property int cfgMaxFps: cfgInt("maxFps", 60, 10, 240)
    property bool cfgPauseWhenHidden: cfgBool("pauseWhenHidden", false)

    property int effectiveCellSize: cfgCellSize
    property real effectiveTps: cfgPhotoSafe
        ? Math.max(
            0.1,
            Math.min(
                12.0,
                cfgTps * (cfgSafeUltraLowTpsEnabled ? cfgSafeUltraLowTps : 1.0)
            )
        )
        : Math.max(0.1, cfgTps)
    property int effectiveMaxFps: cfgMaxFps
    property int simCellBudget: 450000
    property int maxSafetyDownscale: 12
    property int effectiveSimDownscale: safeSimDownscaleForBudget(cfgSimDownscale)
    property int syncStepRate: Math.max(
        1,
        Math.min(
            240,
            Math.max(
                2,
                Math.ceil((effectiveTps / Math.max(1.0, cfgStepsPerFrame)) * 4.0)
            )
        )
    )
    property int effectiveStepRate: Math.max(
        1,
        cfgSyncFpsWithTps ? syncStepRate : effectiveMaxFps
    )
    property int effectiveInjectIntervalMs: cfgPhotoSafe ? Math.max(2500, cfgInjectIntervalMs) : cfgInjectIntervalMs
    property real stepBudget: 0.0

    property int viewportWidthPx: Math.max(1, Math.round(width))
    property int viewportHeightPx: Math.max(1, Math.round(height))
    property int simGridWidth: Math.max(32, Math.floor(viewportWidthPx / Math.max(1, effectiveCellSize * effectiveSimDownscale)))
    property int simGridHeight: Math.max(32, Math.floor(viewportHeightPx / Math.max(1, effectiveCellSize * effectiveSimDownscale)))

    // Some multi-monitor setups report `visible` unreliably per wallpaper instance.
    // Use geometry-based readiness instead of item visibility for simulation gating.
    property bool sceneVisible: opacity > 0.0 && width > 8 && height > 8
    property bool windowVisible: {
        if (!root.window) {
            return true;
        }
        return root.window.visible
            && root.window.visibility !== Window.Hidden
            && root.window.visibility !== Window.Minimized;
    }
    property bool appActive: Qt.application.state === Qt.ApplicationActive
    property bool renderVisibilityGate: !cfgPauseWhenHidden || (windowVisible && appActive)
    property bool renderRunning: sceneVisible && renderVisibilityGate
    property bool clockModeEnabled: cfgClockMode === "Hybrid Local Time"
    property var parsedRuleMasks: parseRuleMasks(cfgRuleString)
    property real ruleBornMask: parsedRuleMasks.born
    property real ruleSurviveMask: parsedRuleMasks.survive
    property real aliveRatioEstimate: startupFixedDensity
    property bool aliveRatioProbeValid: false
    property bool aliveRatioProbeInFlight: false
    property bool aliveRatioProbeSupported: true
    property real aliveRatioProbeNonce: 0.0
    property int aliveRatioLastProbeGeneration: -1
    property int aliveRatioProbeResolution: 24
    property int aliveRatioProbeFailureStreak: 0
    property int aliveRatioProbeSuccessCount: 0
    property int aliveRatioProbeRequestId: 0
    property real aliveRatioSyntheticMomentum: startupFixedDensity
    property int lastStampedCellCount: 0

    function cfgValue(name, fallback) {
        const value = configuration[name];
        if (value === undefined || value === null || value === "") {
            return fallback;
        }
        return value;
    }

    function cfgBool(name, fallback) {
        const value = cfgValue(name, fallback);
        if (typeof value === "boolean") {
            return value;
        }
        const lower = String(value).toLowerCase();
        return lower === "true" || lower === "1";
    }

    function cfgInt(name, fallback, minValue, maxValue) {
        const value = Number(cfgValue(name, fallback));
        if (!Number.isFinite(value)) {
            return fallback;
        }
        return Math.max(minValue, Math.min(maxValue, Math.round(value)));
    }

    function cfgReal(name, fallback, minValue, maxValue) {
        const value = Number(cfgValue(name, fallback));
        if (!Number.isFinite(value)) {
            return fallback;
        }
        return Math.max(minValue, Math.min(maxValue, value));
    }

    function cfgString(name, fallback) {
        return String(cfgValue(name, fallback));
    }

    function cfgColor(name, fallback) {
        const value = configuration[name];
        if (value === undefined || value === null || String(value).length === 0) {
            return fallback;
        }
        return value;
    }

    function paletteColor(key) {
        const selected = paletteDefaults[cfgPalette] || paletteDefaults["Calm Dark"];
        return selected[key];
    }

    function normalizeRule(rule) {
        return String(rule).trim().toUpperCase().replace(/\s+/g, "");
    }

    function rulePartToMask(part) {
        let mask = 0;
        const text = String(part || "");
        for (let i = 0; i < text.length; ++i) {
            const n = Number(text[i]);
            if (Number.isFinite(n) && n >= 0 && n <= 8) {
                mask |= (1 << n);
            }
        }
        return mask;
    }

    function parseRuleMasks(rule) {
        const normalized = normalizeRule(rule);
        const match = /^B([0-8]*)\/S([0-8]*)$/.exec(normalized);
        if (!match) {
            return { born: 8, survive: 12, valid: false, normalized: "B3/S23" };
        }

        return {
            born: rulePartToMask(match[1]),
            survive: rulePartToMask(match[2]),
            valid: true,
            normalized: normalized
        };
    }

    function logDebug(message) {
        if (cfgDebug) {
            console.log("[konway] " + message);
        }
    }

    function clamp01(value) {
        return Math.max(0.0, Math.min(1.0, Number(value)));
    }

    function startupCoverageFromIntensity(intensity) {
        const v = Math.max(0.05, Math.min(1.0, Number(intensity)));
        if (!Number.isFinite(v)) {
            return 0.05;
        }
        // Keep existing default feel at 0.50, but let 1.00 reach full-grid startup coverage.
        if (v <= 0.5) {
            return Math.max(0.005, 0.10 * v);
        }
        const t = (v - 0.5) / 0.5;
        const boosted = 0.05 + (1.0 - 0.05) * Math.pow(t, 2.25);
        return Math.max(0.005, Math.min(1.0, boosted));
    }

    function normalizeProbeChannel(value) {
        const n = Number(value);
        if (!Number.isFinite(n)) {
            return NaN;
        }
        if (n > 1.0) {
            return clamp01(n / 255.0);
        }
        return clamp01(n);
    }

    function sampleProbeImage(image, x, y) {
        if (!image) {
            return NaN;
        }

        if (image.pixel) {
            const rgba = Number(image.pixel(x, y));
            if (Number.isFinite(rgba)) {
                return clamp01(Number((rgba >> 16) & 0xff) / 255.0);
            }
        }

        if (image.pixelColor) {
            const color = image.pixelColor(x, y);
            if (color) {
                let sample = normalizeProbeChannel(color.r);
                if (!Number.isFinite(sample)) {
                    sample = normalizeProbeChannel(color.red);
                }
                if (!Number.isFinite(sample) && typeof color.red === "function") {
                    sample = normalizeProbeChannel(color.red());
                }
                if (!Number.isFinite(sample) && Number.isFinite(Number(color.g)) && Number.isFinite(Number(color.b))) {
                    sample = clamp01((Number(color.r) + Number(color.g) + Number(color.b)) / 3.0);
                }
                if (Number.isFinite(sample)) {
                    return clamp01(sample);
                }
            }
        }

        return NaN;
    }

    function safeSimDownscaleForBudget(requestedDownscale) {
        let downscale = Math.max(1, Math.min(maxSafetyDownscale, Math.round(Number(requestedDownscale))));
        const cellSize = Math.max(1, effectiveCellSize);
        const viewportW = Math.max(1, Math.round(width));
        const viewportH = Math.max(1, Math.round(height));

        let gridW = Math.max(32, Math.floor(viewportW / Math.max(1, cellSize * downscale)));
        let gridH = Math.max(32, Math.floor(viewportH / Math.max(1, cellSize * downscale)));
        let cells = gridW * gridH;

        while (cells > simCellBudget && downscale < maxSafetyDownscale) {
            downscale += 1;
            gridW = Math.max(32, Math.floor(viewportW / Math.max(1, cellSize * downscale)));
            gridH = Math.max(32, Math.floor(viewportH / Math.max(1, cellSize * downscale)));
            cells = gridW * gridH;
        }

        return downscale;
    }

    function applySafeSaturation(colorValue) {
        const luma = colorValue.r * 0.2126 + colorValue.g * 0.7152 + colorValue.b * 0.0722;
        const sat = cfgPhotoSafe ? clamp01(cfgSafeSaturation) : 1.0;
        const r = luma + (colorValue.r - luma) * sat;
        const g = luma + (colorValue.g - luma) * sat;
        const b = luma + (colorValue.b - luma) * sat;
        return Qt.rgba(clamp01(r), clamp01(g), clamp01(b), colorValue.a);
    }

    function renderPaletteActivity(activity, alpha) {
        const contrast = cfgPhotoSafe ? clamp01(cfgSafeContrast) : 1.0;
        const centered = (clamp01(activity) - 0.5) * contrast + 0.5;
        const balanced = clamp01(centered);
        let r = cfgDeadColor.r + (cfgAliveColor.r - cfgDeadColor.r) * balanced;
        let g = cfgDeadColor.g + (cfgAliveColor.g - cfgDeadColor.g) * balanced;
        let b = cfgDeadColor.b + (cfgAliveColor.b - cfgDeadColor.b) * balanced;
        r = cfgBackgroundColor.r + (r - cfgBackgroundColor.r) * 0.9;
        g = cfgBackgroundColor.g + (g - cfgBackgroundColor.g) * 0.9;
        b = cfgBackgroundColor.b + (b - cfgBackgroundColor.b) * 0.9;
        const safeAdjusted = applySafeSaturation(Qt.rgba(clamp01(r), clamp01(g), clamp01(b), 1.0));
        return Qt.rgba(safeAdjusted.r, safeAdjusted.g, safeAdjusted.b, alpha === undefined ? 1.0 : clamp01(alpha));
    }

    function estimateSyntheticAliveRatio() {
        const area = Math.max(1, simGridWidth * simGridHeight);
        const stampBoost = Math.min(0.30, (Math.max(0, lastStampedCellCount) / area) * 7.0);
        const recentPatternBoost = Math.max(
            0.0,
            1.0 - (stepsSincePatternInjection / Math.max(8.0, effectiveTps * 8.0))
        ) * 0.16;
        const stagnationPenalty = Math.min(
            0.24,
            (inactivityCounter / Math.max(120.0, effectiveTps * 28.0)) * 0.24
        );
        const base = startupFixedDensity * 0.55
            + aliveRatioSyntheticMomentum * 0.45
            + stampBoost
            + recentPatternBoost
            - stagnationPenalty;
        return clamp01(base);
    }

    function handleAliveRatioProbeFailure(reason) {
        aliveRatioProbeFailureStreak += 1;
        aliveRatioEstimate = estimateSyntheticAliveRatio();
        aliveRatioLastProbeGeneration = generation;
        if (aliveRatioProbeFailureStreak >= 2) {
            aliveRatioProbeValid = false;
        }
        if (aliveRatioProbeFailureStreak <= 3 || aliveRatioProbeFailureStreak % 10 === 0) {
            logDebug("alive ratio probe fallback (" + reason + ") streak=" + aliveRatioProbeFailureStreak
                + " synthetic=" + aliveRatioEstimate.toFixed(3));
        }
        if (aliveRatioProbeFailureStreak >= 4 && aliveRatioProbeSupported) {
            aliveRatioProbeSupported = false;
            logDebug("alive ratio probe disabled after repeated failures; synthetic metric active");
        }
    }

    function requestAliveRatioProbe(force) {
        if (!simulationInitialized || !renderRunning) {
            return;
        }
        if (!aliveRatioProbeSupported) {
            return;
        }
        if (aliveRatioProbeInFlight) {
            return;
        }
        if (!force && aliveRatioLastProbeGeneration === generation) {
            return;
        }

        aliveRatioProbeInFlight = true;
        aliveRatioProbeNonce = Math.random() * 1000000.0;
        aliveRatioProbeRequestId += 1;
        const requestId = aliveRatioProbeRequestId;
        aliveRatioProbeTimeout.requestId = requestId;
        aliveRatioProbeTimeout.restart();

        aliveRatioProbeTexture.scheduleUpdate();
        aliveRatioProbeTexture.grabToImage(function (result) {
            if (requestId !== aliveRatioProbeRequestId) {
                return;
            }
            aliveRatioProbeTimeout.stop();
            aliveRatioProbeInFlight = false;
            try {
                if (!result || !result.image) {
                    handleAliveRatioProbeFailure("no image");
                    return;
                }

                const image = result.image;
                const w = Math.max(0, image.width);
                const h = Math.max(0, image.height);
                if (w < 1 || h < 1) {
                    handleAliveRatioProbeFailure("empty image");
                    return;
                }

                const stepX = Math.max(1, Math.floor(w / 8));
                const stepY = Math.max(1, Math.floor(h / 8));
                let sum = 0.0;
                let samples = 0;

                for (let y = Math.floor(stepY * 0.5); y < h; y += stepY) {
                    for (let x = Math.floor(stepX * 0.5); x < w; x += stepX) {
                        const sample = sampleProbeImage(image, x, y);

                        if (!Number.isFinite(sample)) {
                            continue;
                        }
                        sum += clamp01(sample);
                        samples += 1;
                    }
                }

                if (samples > 0) {
                    aliveRatioEstimate = clamp01(sum / samples);
                    aliveRatioProbeValid = true;
                    aliveRatioLastProbeGeneration = generation;
                    aliveRatioProbeFailureStreak = 0;
                    aliveRatioProbeSuccessCount += 1;
                    aliveRatioSyntheticMomentum = clamp01(
                        aliveRatioSyntheticMomentum * 0.65 + aliveRatioEstimate * 0.35
                    );
                } else {
                    handleAliveRatioProbeFailure("no samples");
                }
            } catch (error) {
                handleAliveRatioProbeFailure("exception: " + error);
            }
        });
    }

    function parseEnabledCategories() {
        return cfgEnabledCategories.split(",").map(function (entry) {
            return entry.trim();
        }).filter(function (entry) {
            return entry.length > 0;
        });
    }

    function parseCategoryWeights() {
        try {
            const parsed = JSON.parse(cfgCategoryWeights);
            if (typeof parsed === "object" && parsed !== null) {
                return parsed;
            }
        } catch (e) {
        }
        const fallback = {};
        for (const key in defaultCategoryWeights) {
            fallback[key] = defaultCategoryWeights[key];
        }
        return fallback;
    }

    function cellKey(x, y) {
        return String(x) + "," + String(y);
    }

    function projectCellToGrid(xValue, yValue, roundingMode, outsidePolicy) {
        let x = Number(xValue);
        let y = Number(yValue);
        if (!Number.isFinite(x) || !Number.isFinite(y)) {
            return null;
        }

        if (roundingMode === "round") {
            x = Math.round(x);
            y = Math.round(y);
        } else if (roundingMode === "floor") {
            x = Math.floor(x);
            y = Math.floor(y);
        }

        if (cfgWrapEdges) {
            x = ((x % simGridWidth) + simGridWidth) % simGridWidth;
            y = ((y % simGridHeight) + simGridHeight) % simGridHeight;
            return { x: x, y: y };
        }

        const policy = outsidePolicy || "discard";
        if (policy === "clamp") {
            return {
                x: Math.max(0, Math.min(simGridWidth - 1, x)),
                y: Math.max(0, Math.min(simGridHeight - 1, y))
            };
        }
        if (x < 0 || y < 0 || x >= simGridWidth || y >= simGridHeight) {
            return null;
        }
        return { x: x, y: y };
    }

    function uniqueCells(cells) {
        if (!cells || cells.length === 0) {
            return [];
        }

        const seen = {};
        const out = [];
        for (let i = 0; i < cells.length; ++i) {
            const mapped = projectCellToGrid(cells[i].x, cells[i].y, "round", "discard");
            if (!mapped) {
                continue;
            }
            const key = cellKey(mapped.x, mapped.y);
            if (seen[key]) {
                continue;
            }
            seen[key] = true;
            out.push(mapped);
        }
        return out;
    }

    function setClockRegion(x, y, w, h) {
        clockRegionX = Math.max(0, Math.floor(x));
        clockRegionY = Math.max(0, Math.floor(y));
        clockRegionW = Math.max(1, Math.floor(w));
        clockRegionH = Math.max(1, Math.floor(h));
        clockRegionValid = true;
    }

    function clearClockRegion() {
        clockRegionValid = false;
        clockRegionX = 0;
        clockRegionY = 0;
        clockRegionW = 0;
        clockRegionH = 0;
    }

    function isInClockProtectedRegion(x, y) {
        if (!clockModeEnabled || !clockRegionValid) {
            return false;
        }

        const pad = Math.max(2, clockBarrierPadding);
        return x >= (clockRegionX - pad)
            && y >= (clockRegionY - pad)
            && x < (clockRegionX + clockRegionW + pad)
            && y < (clockRegionY + clockRegionH + pad);
    }

    function filterStampCells(cells, allowClockRegion) {
        if (!cells || cells.length === 0) {
            return [];
        }

        const filtered = [];
        const seen = {};
        for (let i = 0; i < cells.length; ++i) {
            const mapped = projectCellToGrid(cells[i].x, cells[i].y, "round", "discard");
            if (!mapped) {
                continue;
            }
            if (!allowClockRegion && isInClockProtectedRegion(mapped.x, mapped.y)) {
                continue;
            }
            const key = cellKey(mapped.x, mapped.y);
            if (seen[key]) {
                continue;
            }
            seen[key] = true;
            filtered.push(mapped);
        }
        return filtered;
    }

    function transitionHash(x, y, seed) {
        const v = Math.sin((x * 12.9898 + y * 78.233 + seed) * 43758.5453123);
        return v - Math.floor(v);
    }

    function resetClockState(resetRegion) {
        clockLastMinuteToken = -1;
        clockLastText = "";
        clockCurrentCells = [];
        clockPreviousCells = [];
        clockNextCells = [];
        clockRenderCells = [];
        clockTransitionStep = 0;
        if (resetRegion) {
            clearClockRegion();
        }
    }

    function clockNowSnapshot() {
        const now = new Date();
        const hh = String(now.getHours()).padStart(2, "0");
        const mm = String(now.getMinutes()).padStart(2, "0");
        return {
            text: hh + ":" + mm,
            minuteToken: now.getHours() * 60 + now.getMinutes()
        };
    }

    function snappedClockScale(rawValue) {
        const stops = [0.35, 0.55, 0.75, 1.00, 1.35, 1.75, 2.00];
        const value = Math.max(0.35, Math.min(2.0, Number(rawValue)));
        let nearest = stops[0];
        let bestDistance = Math.abs(value - nearest);
        for (let i = 1; i < stops.length; ++i) {
            const distance = Math.abs(value - stops[i]);
            if (distance < bestDistance) {
                bestDistance = distance;
                nearest = stops[i];
            }
        }
        return nearest;
    }

    function clockOverlayScale() {
        const s = snappedClockScale(cfgClockScale);
        // Desk Clock: emulate ~1.5px stroke thickness without switching to full 2px blocks.
        if (Math.abs(s - 0.75) < 0.001) {
            return 1.5;
        }
        // Preserve crisp pixel-art look for small tiers (Pocket/Wristwatch/Desk Clock).
        if (s <= 0.80) {
            return 1.0;
        }
        // For bigger tiers, allow controlled enlargement while keeping readability.
        return Math.max(1.0, Math.min(1.38, 0.86 + s * 0.29));
    }

    function buildClockCellsForText(text) {
        if (!text || !text.length) {
            return null;
        }

        const chars = text.split("");
        const scale = snappedClockScale(cfgClockScale);
        const profiles = [
            { scale: 0.35, glyphs: miniClockGlyphs, pixelPitch: 1, pixelBlock: 1, charSpacing: 1, colonSlotFactor: 0.62 },
            { scale: 0.55, glyphs: clockGlyphs, pixelPitch: 1, pixelBlock: 1, charSpacing: 1, colonSlotFactor: 0.52 },
            { scale: 0.75, glyphs: clockGlyphs, pixelPitch: 2, pixelBlock: 1, charSpacing: 2, colonSlotFactor: 0.50 },
            { scale: 1.00, glyphs: clockGlyphs, pixelPitch: 2, pixelBlock: 2, charSpacing: 1, colonSlotFactor: 0.50 },
            { scale: 1.35, glyphs: clockGlyphs, pixelPitch: 3, pixelBlock: 2, charSpacing: 2, colonSlotFactor: 0.48 },
            { scale: 1.75, glyphs: clockGlyphs, pixelPitch: 4, pixelBlock: 3, charSpacing: 2, colonSlotFactor: 0.46 },
            { scale: 2.00, glyphs: clockGlyphs, pixelPitch: 4, pixelBlock: 4, charSpacing: 3, colonSlotFactor: 0.46 }
        ];

        function glyphFor(profile, ch) {
            const set = profile.glyphs || clockGlyphs;
            return set[ch] || set["0"] || clockGlyphs[ch] || clockGlyphs["0"];
        }

        function glyphPixelWidth(profile, glyph) {
            if (!glyph || glyph.length === 0) {
                return 0;
            }
            const glyphW = glyph[0].length;
            return (glyphW - 1) * profile.pixelPitch + profile.pixelBlock;
        }

        function glyphPixelHeight(profile, glyph) {
            if (!glyph || glyph.length === 0) {
                return 0;
            }
            const glyphH = glyph.length;
            return (glyphH - 1) * profile.pixelPitch + profile.pixelBlock;
        }

        function colonAdvanceWidth(profile, glyph) {
            if (!glyph || glyph.length === 0) {
                return 0;
            }
            const baseWidth = glyphPixelWidth(profile, glyph);
            if (chars.length !== 5 || chars[2] !== ":" || chars[0] === undefined || chars[1] === undefined) {
                return baseWidth;
            }
            const refGlyph = glyphFor(profile, "0");
            const refWidth = glyphPixelWidth(profile, refGlyph);
            // Digital clocks look more balanced when ":" occupies about half a digit slot.
            const factor = Math.max(0.35, Math.min(0.80, Number(profile.colonSlotFactor || 0.50)));
            const ideal = Math.max(baseWidth, Math.floor(refWidth * factor));
            return ideal;
        }

        function glyphAdvanceWidth(profile, ch, glyph) {
            if (ch === ":") {
                return colonAdvanceWidth(profile, glyph);
            }
            return glyphPixelWidth(profile, glyph);
        }

        function glyphDrawOffsetX(profile, ch, glyph) {
            if (ch !== ":") {
                return 0;
            }
            const advance = glyphAdvanceWidth(profile, ch, glyph);
            const base = glyphPixelWidth(profile, glyph);
            return Math.max(0, Math.floor((advance - base) * 0.5));
        }

        function measurePattern(profile) {
            let w = 0;
            let h = 0;
            for (let i = 0; i < chars.length; ++i) {
                const ch = chars[i];
                const glyph = glyphFor(profile, ch);
                if (!glyph || glyph.length === 0) {
                    continue;
                }
                const glyphPixelW = glyphAdvanceWidth(profile, ch, glyph);
                const glyphPixelH = glyphPixelHeight(profile, glyph);
                w += glyphPixelW;
                if (i < chars.length - 1) {
                    w += profile.charSpacing;
                }
                h = Math.max(h, glyphPixelH);
            }
            return { w: w, h: h };
        }

        let profileIndex = 0;
        let bestDistance = 999.0;
        for (let i = 0; i < profiles.length; ++i) {
            const distance = Math.abs(scale - profiles[i].scale);
            if (distance < bestDistance) {
                bestDistance = distance;
                profileIndex = i;
            }
        }

        let profile = profiles[profileIndex];
        let measured = measurePattern(profile);

        // Keep geometry distinct by selected size as much as possible.
        // Only downshift if the chosen profile cannot fit in current simulation grid.
        while (profileIndex > 0 && (measured.w + 3 >= simGridWidth || measured.h + 3 >= simGridHeight)) {
            profileIndex -= 1;
            profile = profiles[profileIndex];
            measured = measurePattern(profile);
        }

        const totalW = measured.w;
        const totalH = measured.h;
        if (totalW < 1 || totalH < 1) {
            return null;
        }
        if (totalW + 3 >= simGridWidth || totalH + 3 >= simGridHeight) {
            return null;
        }

        const originX = Math.max(1, Math.floor((simGridWidth - totalW) * 0.5));
        const originY = Math.max(1, Math.floor((simGridHeight - totalH) * 0.5));

        const cells = [];
        let cursor = 0;

        for (let ci = 0; ci < chars.length; ++ci) {
            const ch = chars[ci];
            const glyph = glyphFor(profile, ch);
            if (!glyph || glyph.length === 0) {
                continue;
            }

            const drawOffsetX = glyphDrawOffsetX(profile, ch, glyph);
            for (let gy = 0; gy < glyph.length; ++gy) {
                const row = glyph[gy];
                for (let gx = 0; gx < row.length; ++gx) {
                    if (row[gx] !== "1") {
                        continue;
                    }

                    const baseX = originX + cursor + drawOffsetX + gx * profile.pixelPitch;
                    const baseY = originY + gy * profile.pixelPitch;

                    for (let by = 0; by < profile.pixelBlock; ++by) {
                        for (let bx = 0; bx < profile.pixelBlock; ++bx) {
                            cells.push({ x: baseX + bx, y: baseY + by });
                        }
                    }
                }
            }

            cursor += glyphAdvanceWidth(profile, ch, glyph);
            if (ci < chars.length - 1) {
                cursor += profile.charSpacing;
            }
        }

        const deduped = uniqueCells(cells);
        if (deduped.length === 0) {
            return null;
        }

        return {
            x: originX,
            y: originY,
            w: totalW,
            h: totalH,
            cells: deduped
        };
    }

    function clearClockPatternFromSimulation() {
        // Clock exclusion is handled in life_step shader; only reset overlay state.
        resetClockState(true);
    }

    function scheduleClockPattern(pattern, forceInstant) {
        if (!pattern || !pattern.cells || pattern.cells.length === 0) {
            return false;
        }

        if (!clockCurrentCells.length || forceInstant) {
            setClockRegion(pattern.x, pattern.y, pattern.w, pattern.h);
            clockCurrentCells = pattern.cells;
            clockPreviousCells = [];
            clockNextCells = [];
            clockRenderCells = pattern.cells;
            clockTransitionStep = 0;
            return true;
        }

        const unionX = Math.min(clockRegionX, pattern.x);
        const unionY = Math.min(clockRegionY, pattern.y);
        const unionW = Math.max(clockRegionX + clockRegionW, pattern.x + pattern.w) - unionX;
        const unionH = Math.max(clockRegionY + clockRegionH, pattern.y + pattern.h) - unionY;
        setClockRegion(unionX, unionY, unionW, unionH);

        clockPreviousCells = clockCurrentCells;
        clockNextCells = pattern.cells;
        clockRenderCells = clockCurrentCells;
        clockTransitionStep = 0;
        return true;
    }

    function refreshClock(forceInstant) {
        if (!clockModeEnabled || !simulationInitialized || !renderRunning) {
            return;
        }

        const snapshot = clockNowSnapshot();
        if (!forceInstant && snapshot.minuteToken === clockLastMinuteToken) {
            return;
        }

        const pattern = buildClockCellsForText(snapshot.text);
        if (!pattern) {
            return;
        }

        if (scheduleClockPattern(pattern, forceInstant)) {
            clockLastMinuteToken = snapshot.minuteToken;
            clockLastText = snapshot.text;
        }
    }

    function maintainClockDisplay() {
        if (!clockModeEnabled || !simulationInitialized || !renderRunning) {
            return;
        }

        if (!clockCurrentCells || clockCurrentCells.length === 0 || !clockRegionValid) {
            refreshClock(true);
        }
    }

    function runClockTransitionStep() {
        if (!clockModeEnabled) {
            return;
        }

        if (!clockPreviousCells.length || !clockNextCells.length) {
            clockRenderCells = clockCurrentCells;
            return;
        }

        const totalSteps = Math.max(1, clockTransitionTotalSteps);
        const nextStep = Math.min(totalSteps, clockTransitionStep + 1);
        const progress = nextStep / totalSteps;

        const oldSet = {};
        for (let i = 0; i < clockPreviousCells.length; ++i) {
            oldSet[cellKey(clockPreviousCells[i].x, clockPreviousCells[i].y)] = true;
        }

        const newSet = {};
        for (let j = 0; j < clockNextCells.length; ++j) {
            newSet[cellKey(clockNextCells[j].x, clockNextCells[j].y)] = true;
        }

        const renderCells = [];
        const seen = {};
        for (let oi = 0; oi < clockPreviousCells.length; ++oi) {
            const oldCell = clockPreviousCells[oi];
            const oldKey = cellKey(oldCell.x, oldCell.y);
            if (newSet[oldKey]) {
                if (!seen[oldKey]) {
                    seen[oldKey] = true;
                    renderCells.push(oldCell);
                }
                continue;
            }
            if (transitionHash(oldCell.x, oldCell.y, 17.0) > progress) {
                if (!seen[oldKey]) {
                    seen[oldKey] = true;
                    renderCells.push(oldCell);
                }
            }
        }

        for (let ni = 0; ni < clockNextCells.length; ++ni) {
            const newCell = clockNextCells[ni];
            const newKey = cellKey(newCell.x, newCell.y);
            if (oldSet[newKey]) {
                continue;
            }
            if (transitionHash(newCell.x, newCell.y, 73.0) <= progress) {
                if (!seen[newKey]) {
                    seen[newKey] = true;
                    renderCells.push(newCell);
                }
            }
        }

        clockRenderCells = renderCells;
        clockTransitionStep = nextStep;
        if (clockTransitionStep >= totalSteps) {
            clockCurrentCells = clockNextCells;
            clockPreviousCells = [];
            clockNextCells = [];
            clockRenderCells = clockCurrentCells;
        }
    }

    function weightedRandomChoice(candidates) {
        if (!candidates || candidates.length === 0) {
            return null;
        }

        let total = 0.0;
        for (let i = 0; i < candidates.length; ++i) {
            const weight = Math.max(0.0001, Number(candidates[i].effectiveWeight || 0.0001));
            total += weight;
        }

        let cursor = Math.random() * total;
        for (let j = 0; j < candidates.length; ++j) {
            const weight = Math.max(0.0001, Number(candidates[j].effectiveWeight || 0.0001));
            cursor -= weight;
            if (cursor <= 0.0) {
                return candidates[j];
            }
        }
        return candidates[candidates.length - 1];
    }

    function pickPatternCandidate(preferredId, modeOverride) {
        if (preferredId && patternById[preferredId]) {
            return patternById[preferredId];
        }

        const enabledCategories = parseEnabledCategories();
        const enabledSet = {};
        for (let i = 0; i < enabledCategories.length; ++i) {
            enabledSet[enabledCategories[i]] = true;
        }

        const mode = modeOverride || cfgInjectorMode;
        const categoryWeights = parseCategoryWeights();
        const allowLarge = cfgAllowLargePatterns;
        const maxSize = cfgMaxPatternSize;
        const rule = normalizeRule(cfgRuleString);

        let candidates = patternCatalog.filter(function (entry) {
            if (!enabledSet[entry.category]) {
                return false;
            }
            if (!allowLarge && Math.max(entry.bboxW || 0, entry.bboxH || 0) > maxSize) {
                return false;
            }
            if (entry.rule && normalizeRule(entry.rule) !== rule) {
                return false;
            }
            return true;
        });

        if (mode === "Curated") {
            const curatedSet = {};
            for (let c = 0; c < coreCuratedIds.length; ++c) {
                curatedSet[coreCuratedIds[c]] = true;
            }
            candidates = candidates.filter(function (entry) {
                return !!curatedSet[entry.id];
            });
        } else if (mode === "Random Small") {
            candidates = candidates.filter(function (entry) {
                return (entry.bboxW || 0) <= 48 && (entry.bboxH || 0) <= 48;
            });
        } else if (mode === "Methuselah") {
            candidates = candidates.filter(function (entry) {
                return entry.category === "methuselahs";
            });
        } else if (mode === "Ships") {
            candidates = candidates.filter(function (entry) {
                return entry.category === "spaceships" || entry.category === "gliders";
            });
        }

        if (candidates.length === 0) {
            return null;
        }

        const methuselahs = candidates.filter(function (entry) {
            return entry.category === "methuselahs";
        });
        if (methuselahs.length > 0 && Math.random() < cfgRarePatternChance) {
            for (let m = 0; m < methuselahs.length; ++m) {
                methuselahs[m].effectiveWeight = Math.max(0.01, Number(methuselahs[m].weight || 1.0));
            }
            return weightedRandomChoice(methuselahs);
        }

        for (let k = 0; k < candidates.length; ++k) {
            const baseWeight = Math.max(0.01, Number(candidates[k].weight || 1.0));
            const catWeight = Math.max(0.01, Number(categoryWeights[candidates[k].category] || 1.0));
            candidates[k].effectiveWeight = baseWeight * catWeight;
        }

        return weightedRandomChoice(candidates);
    }

    function loadPatternIndex() {
        if (!PatternData || !PatternData.patternIndex || !PatternData.patternIndex.patterns) {
            patternCatalog = [];
            patternById = {};
            logDebug("pattern index unavailable; injector will use fallback seeds only");
            return;
        }

        try {
            patternCatalog = PatternData.patternIndex.patterns || [];
            const map = {};
            for (let i = 0; i < patternCatalog.length; ++i) {
                map[patternCatalog[i].id] = patternCatalog[i];
            }
            patternById = map;
            logDebug("loaded " + patternCatalog.length + " patterns");
        } catch (e) {
            patternCatalog = [];
            patternById = {};
            logDebug("failed to parse pattern index: " + e);
        }
    }

    function parseRleText(text, hardCellLimit) {
        const lines = text.split(/\r?\n/);
        let headerX = 0;
        let headerY = 0;
        let rule = "B3/S23";
        const dataLines = [];

        const headerRegex = /x\s*=\s*(\d+)\s*,\s*y\s*=\s*(\d+)(?:\s*,\s*rule\s*=\s*([^\s]+))?/i;
        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i].trim();
            if (!line) {
                continue;
            }
            if (line.startsWith("#")) {
                continue;
            }
            const headerMatch = headerRegex.exec(line);
            if (headerMatch) {
                headerX = Number(headerMatch[1]);
                headerY = Number(headerMatch[2]);
                if (headerMatch[3]) {
                    rule = String(headerMatch[3]).toUpperCase();
                }
                continue;
            }
            dataLines.push(line);
        }

        const encoded = dataLines.join("");
        const cells = [];
        let x = 0;
        let y = 0;
        let run = "";
        let maxX = 0;
        let maxY = 0;

        for (let p = 0; p < encoded.length; ++p) {
            const ch = encoded[p];
            if (ch >= "0" && ch <= "9") {
                run += ch;
                continue;
            }

            const count = run.length > 0 ? Number(run) : 1;
            run = "";

            if (ch === "b") {
                x += count;
            } else if (ch === "o") {
                for (let n = 0; n < count; ++n) {
                    cells.push({ x: x + n, y: y });
                    if (cells.length > hardCellLimit) {
                        return null;
                    }
                }
                x += count;
                maxX = Math.max(maxX, x);
                maxY = Math.max(maxY, y + 1);
            } else if (ch === "$") {
                y += count;
                x = 0;
                maxY = Math.max(maxY, y + 1);
            } else if (ch === "!") {
                break;
            }
        }

        return {
            cells: cells,
            bboxW: Math.max(headerX, maxX),
            bboxH: Math.max(headerY, maxY),
            rule: rule
        };
    }

    function getBuiltinGosperPattern() {
        if (builtinPatternCache.gosper) {
            return builtinPatternCache.gosper;
        }

        const parsed = parseRleText(builtinGosperRle, 8192);
        if (parsed) {
            builtinPatternCache.gosper = parsed;
        }
        return parsed;
    }

    function loadRleCells(entry) {
        if (!entry || !entry.id) {
            return null;
        }

        if (parsedRleCache[entry.id]) {
            return parsedRleCache[entry.id];
        }

        if (!PatternData || !PatternData.patternCellsById || !PatternData.patternCellsById[entry.id]) {
            logDebug("missing compiled pattern data for " + entry.id);
            return null;
        }

        const parsed = PatternData.patternCellsById[entry.id];
        parsedRleCache[entry.id] = parsed;
        return parsed;
    }

    function transformCells(pattern, rotateSteps, flipX, flipY) {
        const rotation = ((rotateSteps % 4) + 4) % 4;
        const sourceW = pattern.bboxW;
        const sourceH = pattern.bboxH;
        const outW = (rotation % 2 === 0) ? sourceW : sourceH;
        const outH = (rotation % 2 === 0) ? sourceH : sourceW;

        const transformed = [];
        for (let i = 0; i < pattern.cells.length; ++i) {
            let x = pattern.cells[i].x;
            let y = pattern.cells[i].y;
            let tx = x;
            let ty = y;

            if (rotation === 1) {
                tx = sourceH - 1 - y;
                ty = x;
            } else if (rotation === 2) {
                tx = sourceW - 1 - x;
                ty = sourceH - 1 - y;
            } else if (rotation === 3) {
                tx = y;
                ty = sourceW - 1 - x;
            }

            if (flipX) {
                tx = outW - 1 - tx;
            }
            if (flipY) {
                ty = outH - 1 - ty;
            }

            transformed.push({ x: tx, y: ty });
        }

        return {
            cells: transformed,
            bboxW: outW,
            bboxH: outH,
            rule: pattern.rule
        };
    }

    function writeStampCells(stampCells, allowClockRegion) {
        const filtered = filterStampCells(stampCells, allowClockRegion === true);
        stampCanvas.pendingCells = filtered;
        stampCanvas.requestPaint();
        stampTexture.scheduleUpdate();
        stampActive = filtered.length > 0;
        stampHoldSteps = stampActive ? 1 : 0;
        stampClearPending = false;
        const area = Math.max(1, simGridWidth * simGridHeight);
        lastStampedCellCount = filtered.length;
        if (filtered.length > 0) {
            aliveRatioSyntheticMomentum = clamp01(
                aliveRatioSyntheticMomentum * 0.80 + (filtered.length / area) * 8.0
            );
        }
        return stampActive;
    }

    function appendStampCells(extraCells, allowClockRegion) {
        if (!extraCells || extraCells.length === 0) {
            return false;
        }
        const filtered = filterStampCells(extraCells, allowClockRegion === true);
        if (filtered.length === 0) {
            return false;
        }
        let merged = (stampCanvas.pendingCells || []).concat(filtered);
        merged = uniqueCells(merged);
        if (merged.length > 65536) {
            merged = merged.slice(merged.length - 65536);
        }
        stampCanvas.pendingCells = merged;
        stampCanvas.requestPaint();
        stampTexture.scheduleUpdate();
        stampActive = true;
        stampHoldSteps = Math.max(stampHoldSteps, 1);
        stampClearPending = false;
        const area = Math.max(1, simGridWidth * simGridHeight);
        lastStampedCellCount = filtered.length;
        aliveRatioSyntheticMomentum = clamp01(
            aliveRatioSyntheticMomentum * 0.80 + (filtered.length / area) * 8.0
        );
        return true;
    }

    function buildRandomCluster(cellCount, clusterRadius) {
        const count = Math.max(1, Math.min(128, Math.round(cellCount)));
        const radius = Math.max(0, Math.min(12, Math.round(clusterRadius)));
        const cx = Math.floor(Math.random() * Math.max(1, simGridWidth));
        const cy = Math.floor(Math.random() * Math.max(1, simGridHeight));
        const cells = [];

        for (let i = 0; i < count; ++i) {
            const mapped = projectCellToGrid(
                cx + Math.floor((Math.random() * (radius * 2 + 1)) - radius),
                cy + Math.floor((Math.random() * (radius * 2 + 1)) - radius),
                "floor",
                "discard"
            );
            if (!mapped) {
                continue;
            }
            cells.push(mapped);
        }

        return cells;
    }

    function seedRandomCluster(cellCount, clusterRadius) {
        const cells = buildRandomCluster(cellCount, clusterRadius);
        if (!cells.length) {
            return false;
        }
        if (!appendStampCells(cells)) {
            return false;
        }
        inactivityCounter = 0;
        logDebug("micro seed cluster: " + cells.length + " cells");
        return true;
    }

    function buildStartupScatterCells() {
        const cells = [];
        const density = startupFixedDensity;
        const intensity = startupSeedIntensity;
        const area = Math.max(1, simGridWidth * simGridHeight);
        const targetDensity = Math.max(0.0025, Math.min(1.0, density));

        if (targetDensity >= 0.999) {
            const full = [];
            for (let y = 0; y < simGridHeight; ++y) {
                for (let x = 0; x < simGridWidth; ++x) {
                    full.push({ x: x, y: y });
                }
            }
            return full;
        }

        const minByPerimeter = Math.max(24, Math.round((simGridWidth + simGridHeight) * (0.20 + intensity * 0.50)));
        const targetCount = Math.max(minByPerimeter, Math.min(area, Math.round(area * targetDensity)));
        const hardCap = Math.min(
            area,
            Math.max(targetCount + Math.round(targetCount * (0.25 + intensity * 0.45)), targetCount + 64)
        );

        const aspect = simGridWidth / Math.max(1, simGridHeight);
        const cols = Math.max(8, Math.round(Math.sqrt(targetCount * aspect)));
        const rows = Math.max(8, Math.round(targetCount / Math.max(1, cols)));
        const tileW = simGridWidth / cols;
        const tileH = simGridHeight / rows;

        // Resolution-aware stratified pass: touches the full grid area uniformly.
        for (let ry = 0; ry < rows; ++ry) {
            for (let rx = 0; rx < cols; ++rx) {
                if (cells.length >= hardCap) {
                    break;
                }

                const primary = projectCellToGrid(
                    (rx + 0.5) * tileW + (Math.random() * 2.0 - 1.0) * tileW * 0.45,
                    (ry + 0.5) * tileH + (Math.random() * 2.0 - 1.0) * tileH * 0.45,
                    "floor",
                    "clamp"
                );
                if (!primary) {
                    continue;
                }
                const px = primary.x;
                const py = primary.y;
                cells.push(primary);

                const extraChance = 0.04 + intensity * 0.34;
                const extra = Math.random() < extraChance
                    ? (1 + (Math.random() < (0.05 + intensity * 0.16) ? 1 : 0))
                    : 0;
                for (let e = 0; e < extra && cells.length < hardCap; ++e) {
                    const neighbor = projectCellToGrid(
                        px + Math.floor((Math.random() * 3.0) - 1.0),
                        py + Math.floor((Math.random() * 3.0) - 1.0),
                        "floor",
                        "clamp"
                    );
                    if (!neighbor) {
                        continue;
                    }
                    cells.push(neighbor);
                }
            }
            if (cells.length >= hardCap) {
                break;
            }
        }

        // Extra bottom coverage to avoid visually empty lower edge on first seed.
        const bottomBandRows = Math.max(2, Math.floor(simGridHeight * (0.04 + intensity * 0.10)));
        const bottomStart = Math.max(0, simGridHeight - bottomBandRows);
        const bottomCols = Math.max(8, Math.floor(simGridWidth * (0.08 + intensity * 0.24)));
        const slotW = simGridWidth / Math.max(1, bottomCols);
        for (let i = 0; i < bottomCols && cells.length < hardCap; ++i) {
            const anchor = projectCellToGrid(
                (i + Math.random()) * slotW,
                bottomStart + Math.floor(Math.random() * Math.max(1, bottomBandRows)),
                "floor",
                "clamp"
            );
            if (!anchor) {
                continue;
            }
            cells.push(anchor);
            if (Math.random() < (0.18 + intensity * 0.45) && cells.length < hardCap) {
                const extra = projectCellToGrid(
                    anchor.x + (Math.random() < 0.5 ? -1 : 1),
                    anchor.y + (Math.random() < 0.5 ? -1 : 1),
                    "floor",
                    "clamp"
                );
                if (extra) {
                    cells.push(extra);
                }
            }
        }

        const clusterBursts = Math.max(1, Math.round((simGridWidth + simGridHeight) * (0.002 + intensity * 0.006)));
        for (let b = 0; b < clusterBursts && cells.length < hardCap; ++b) {
            const burst = buildRandomCluster(
                1 + Math.round(Math.random() * (1 + intensity * 3)),
                1 + Math.round(intensity * 2)
            );
            for (let bi = 0; bi < burst.length && cells.length < hardCap; ++bi) {
                cells.push(burst[bi]);
            }
        }

        while (cells.length < targetCount) {
            cells.push({
                x: Math.floor(Math.random() * Math.max(1, simGridWidth)),
                y: Math.floor(Math.random() * Math.max(1, simGridHeight))
            });
        }

        const unique = uniqueCells(cells);
        if (unique.length >= targetCount) {
            return unique;
        }

        const seen = {};
        for (let i = 0; i < unique.length; ++i) {
            seen[cellKey(unique[i].x, unique[i].y)] = true;
        }

        for (let y = 0; y < simGridHeight; ++y) {
            for (let x = 0; x < simGridWidth; ++x) {
                const key = cellKey(x, y);
                if (seen[key]) {
                    continue;
                }
                unique.push({ x: x, y: y });
                seen[key] = true;
                if (unique.length >= targetCount) {
                    return unique;
                }
            }
        }

        return unique;
    }

    function seedStartupScatter() {
        const cells = buildStartupScatterCells();
        if (!cells.length) {
            return false;
        }
        if (!appendStampCells(cells)) {
            return false;
        }
        stampHoldSteps = Math.max(stampHoldSteps, 2);
        inactivityCounter = 0;
        logDebug("startup organic scatter: " + cells.length + " cells");
        return true;
    }

    function appendPatternCells(out, pattern, baseX, baseY) {
        for (let i = 0; i < pattern.length; ++i) {
            const mapped = projectCellToGrid(
                baseX + pattern[i].x,
                baseY + pattern[i].y,
                "floor",
                "discard"
            );
            if (!mapped) {
                continue;
            }
            out.push(mapped);
        }
    }

    function seedGuaranteedKickstart() {
        const anchors = [
            { x: Math.floor(simGridWidth * 0.22), y: Math.floor(simGridHeight * 0.24) },
            { x: Math.floor(simGridWidth * 0.72), y: Math.floor(simGridHeight * 0.28) },
            { x: Math.floor(simGridWidth * 0.30), y: Math.floor(simGridHeight * 0.70) },
            { x: Math.floor(simGridWidth * 0.76), y: Math.floor(simGridHeight * 0.72) }
        ];
        const rPent = [
            { x: 1, y: 0 }, { x: 2, y: 0 }, { x: 0, y: 1 }, { x: 1, y: 1 }, { x: 1, y: 2 }
        ];
        const glider = [
            { x: 1, y: 0 }, { x: 2, y: 1 }, { x: 0, y: 2 }, { x: 1, y: 2 }, { x: 2, y: 2 }
        ];
        const block = [
            { x: 0, y: 0 }, { x: 1, y: 0 }, { x: 0, y: 1 }, { x: 1, y: 1 }
        ];

        const cells = [];
        for (let a = 0; a < anchors.length; ++a) {
            const ax = anchors[a].x;
            const ay = anchors[a].y;
            if (isInClockProtectedRegion(ax, ay)) {
                continue;
            }
            appendPatternCells(cells, rPent, ax, ay);
            appendPatternCells(cells, block, ax + 4, ay + 1);
            if (Math.random() < (0.35 + startupSeedIntensity * 0.45)) {
                appendPatternCells(cells, glider, ax - 5, ay - 2);
            }
        }

        const unique = uniqueCells(cells);
        if (unique.length > 0 && appendStampCells(unique)) {
            stampHoldSteps = Math.max(stampHoldSteps, Math.round(4 + startupSeedIntensity * 6));
            inactivityCounter = 0;
            logDebug("guaranteed kickstart seed: " + unique.length + " cells");
            return true;
        }

        return seedRandomCluster(6 + Math.round(8 * startupSeedIntensity), 3);
    }

    function seedBrushAtScreen(screenX, screenY) {
        if (!simulationInitialized || simGridWidth < 1 || simGridHeight < 1) {
            return;
        }

        const gx = Math.floor((screenX / Math.max(1, width)) * simGridWidth);
        const gy = Math.floor((screenY / Math.max(1, height)) * simGridHeight);
        const radius = Math.max(0, cfgCursorBrushSize - 1);
        const cells = [];

        for (let oy = -radius; oy <= radius; ++oy) {
            for (let ox = -radius; ox <= radius; ++ox) {
                if (ox * ox + oy * oy > radius * radius) {
                    continue;
                }

                const mapped = projectCellToGrid(gx + ox, gy + oy, "floor", "discard");
                if (!mapped) {
                    continue;
                }
                cells.push(mapped);
            }
        }

        appendStampCells(cells);
    }

    function stampPatternAtScreen(patternId, screenX, screenY, allowRandomTransform) {
        const entry = patternById[patternId];
        if (!entry) {
            return false;
        }

        const loaded = loadRleCells(entry);
        if (!loaded) {
            return false;
        }

        let pattern = loaded;
        if (allowRandomTransform) {
            pattern = transformCells(
                loaded,
                Math.floor(Math.random() * 4),
                Math.random() < 0.5,
                Math.random() < 0.5
            );
        }

        const gx = Math.floor((screenX / Math.max(1, width)) * simGridWidth);
        const gy = Math.floor((screenY / Math.max(1, height)) * simGridHeight);
        const originX = gx - Math.floor(pattern.bboxW * 0.5);
        const originY = gy - Math.floor(pattern.bboxH * 0.5);
        const stampCells = [];

        for (let i = 0; i < pattern.cells.length; ++i) {
            const mapped = projectCellToGrid(
                originX + pattern.cells[i].x,
                originY + pattern.cells[i].y,
                "floor",
                "discard"
            );
            if (!mapped) {
                continue;
            }
            stampCells.push(mapped);
        }

        if (!stampCells.length) {
            return false;
        }

        if (!appendStampCells(stampCells)) {
            return false;
        }
        inactivityCounter = 0;
        return true;
    }

    function clearStampTexture() {
        stampCanvas.pendingCells = [];
        stampCanvas.requestPaint();
        stampTexture.scheduleUpdate();
        stampActive = false;
        stampHoldSteps = 0;
        stampClearPending = false;
        lastStampedCellCount = 0;
    }

    function writeKillCells(killCells, allowClockRegion) {
        const filtered = filterStampCells(killCells, allowClockRegion === true);
        killCanvas.pendingCells = filtered;
        killCanvas.requestPaint();
        killTexture.scheduleUpdate();
        killActive = filtered.length > 0;
        killHoldSteps = killActive ? 1 : 0;
        killClearPending = false;
    }

    function clearKillTexture() {
        killCanvas.pendingCells = [];
        killCanvas.requestPaint();
        killTexture.scheduleUpdate();
        killActive = false;
        killHoldSteps = 0;
        killClearPending = false;
    }

    function buildPatternStampCells(loaded, centerPlacement, allowRandomTransform) {
        if (!loaded) {
            return [];
        }

        let pattern = loaded;
        if (allowRandomTransform) {
            pattern = transformCells(
                loaded,
                Math.floor(Math.random() * 4),
                Math.random() < 0.5,
                Math.random() < 0.5
            );
        }

        let originX;
        let originY;
        if (centerPlacement) {
            originX = Math.floor((simGridWidth - pattern.bboxW) * 0.5);
            originY = Math.floor((simGridHeight - pattern.bboxH) * 0.5);
        } else {
            originX = Math.floor(Math.random() * Math.max(1, simGridWidth));
            originY = Math.floor(Math.random() * Math.max(1, simGridHeight));
        }

        const stampCells = [];
        for (let i = 0; i < pattern.cells.length; ++i) {
            const mapped = projectCellToGrid(
                originX + pattern.cells[i].x,
                originY + pattern.cells[i].y,
                "floor",
                "discard"
            );
            if (!mapped) {
                continue;
            }
            stampCells.push(mapped);
        }

        return stampCells;
    }

    function stampPatternData(loaded, centerPlacement, allowRandomTransform) {
        const stampCells = buildPatternStampCells(loaded, centerPlacement, allowRandomTransform);
        if (stampCells.length === 0) {
            return false;
        }

        return writeStampCells(stampCells);
    }

    function appendPatternData(loaded, centerPlacement, allowRandomTransform) {
        const stampCells = buildPatternStampCells(loaded, centerPlacement, allowRandomTransform);
        if (stampCells.length === 0) {
            return false;
        }

        return appendStampCells(stampCells);
    }

    function appendPatternDataComplete(loaded, centerPlacement, allowRandomTransform, maxAttempts) {
        if (!loaded) {
            return false;
        }

        const attempts = Math.max(1, Math.round(maxAttempts || 1));
        for (let attempt = 0; attempt < attempts; ++attempt) {
            const useCenter = centerPlacement && attempt === 0;
            const stampCells = buildPatternStampCells(loaded, useCenter, allowRandomTransform);
            if (!stampCells.length) {
                continue;
            }

            // Ensure protected clock area is not clipping the stamp (keeps pattern intact).
            const filtered = filterStampCells(stampCells, false);
            if (filtered.length !== stampCells.length) {
                continue;
            }

            if (appendStampCells(filtered, true)) {
                return true;
            }
        }

        return false;
    }

    function stampPattern(entry, centerPlacement, allowRandomTransform) {
        if (!entry) {
            return false;
        }

        const loaded = loadRleCells(entry);
        if (!loaded) {
            return false;
        }

        if (!cfgAllowLargePatterns && Math.max(loaded.bboxW, loaded.bboxH) > cfgMaxPatternSize) {
            return false;
        }

        return stampPatternData(loaded, centerPlacement, allowRandomTransform);
    }

    function injectGuaranteedStartupGosper() {
        const packEntry = patternById["gosperglidergun"];
        if (packEntry) {
            const packedData = loadRleCells(packEntry);
            const packed = packedData
                ? appendPatternDataComplete(packedData, !clockModeEnabled, false, clockModeEnabled ? 24 : 2)
                : false;
            if (packed) {
                stepsSincePatternInjection = 0;
                logDebug("startup gosper injected from pattern pack");
                return true;
            }
            if (packedData && clockModeEnabled && appendPatternData(packedData, false, false)) {
                stepsSincePatternInjection = 0;
                logDebug("startup gosper partially injected from pattern pack (clock-safe fallback)");
                return true;
            }
        }

        const builtin = getBuiltinGosperPattern();
        if (!builtin) {
            return false;
        }

        const fallback = appendPatternDataComplete(builtin, !clockModeEnabled, false, clockModeEnabled ? 24 : 2);
        if (fallback) {
            stepsSincePatternInjection = 0;
            logDebug("startup gosper injected from builtin fallback");
            return true;
        }
        if (clockModeEnabled && appendPatternData(builtin, false, false)) {
            stepsSincePatternInjection = 0;
            logDebug("startup gosper partially injected from builtin fallback (clock-safe fallback)");
            return true;
        }
        return false;
    }

    function injectPattern(preferredId, centerPlacement, modeOverride) {
        const candidate = pickPatternCandidate(preferredId, modeOverride);
        if (!candidate) {
            return false;
        }

        const ok = stampPattern(candidate, centerPlacement, !centerPlacement);
        if (ok) {
            inactivityCounter = 0;
            stepsSincePatternInjection = 0;
            logDebug("injected pattern: " + candidate.id);
        }
        return ok;
    }

    function injectRescuePattern() {
        const centerPlacement = !clockModeEnabled;
        const rescueIds = ["lwss", "glider", "acorn", "diehard", "gosperglidergun"];
        for (let i = 0; i < rescueIds.length; ++i) {
            for (let attempt = 0; attempt < 2; ++attempt) {
                if (injectPattern(rescueIds[i], centerPlacement, "Ships")) {
                    logDebug("rescue injection: " + rescueIds[i] + " attempt=" + (attempt + 1));
                    return true;
                }
            }
        }
        return false;
    }

    function maybeInjectEnergy() {
        if (!cfgAutoInject || !simulationInitialized) {
            return;
        }

        requestAliveRatioProbe(false);
        if (!aliveRatioProbeValid && !aliveRatioProbeInFlight) {
            requestAliveRatioProbe(true);
        }

        const minTarget = clamp01(cfgMinAliveRatio);
        const aliveRatio = aliveRatioProbeValid
            ? clamp01(aliveRatioEstimate)
            : estimateSyntheticAliveRatio();
        if (!aliveRatioProbeValid) {
            aliveRatioEstimate = aliveRatio;
        }
        const deficit = Math.max(0.0, minTarget - aliveRatio);
        const deficitPressure = Math.min(1.0, deficit / Math.max(0.04, minTarget));
        const surplus = Math.max(0.0, aliveRatio - minTarget);
        const surplusPressure = Math.min(1.0, surplus / Math.max(0.05, 1.0 - minTarget));

        const stagnation = Math.min(1.0, inactivityCounter / Math.max(12.0, effectiveTps * 3.0));
        const clockModeFactor = clockModeEnabled ? 0.42 : 1.0;
        const forcedBase = Math.max(0.0, Math.min(1.0, cfgForcedInjectChance * clockModeFactor));
        const forced = forcedBase * (1.0 - 0.75 * surplusPressure);
        const hardRescueSteps = Math.max(90, Math.round(effectiveTps * 18));
        const rescueThresholdSteps = Math.max(120, Math.round(effectiveTps * 45));
        const rescueReady = rescueCooldownSteps <= 0;

        logDebug("inject tick alive=" + aliveRatio.toFixed(3)
            + " target=" + minTarget.toFixed(3)
            + " deficit=" + deficit.toFixed(3)
            + " stagnation=" + stagnation.toFixed(3));

        // If current population is clearly below target, prioritize strong rescue patterns.
        if (rescueReady && deficit > 0.08) {
            if (!injectRescuePattern()) {
                seedRandomCluster(clockModeEnabled ? 7 : 12, 4);
            }
            rescueCooldownSteps = Math.max(24, Math.round(effectiveTps * 10));
            return;
        }

        // Independent rescue: even if micro seeding keeps resetting inactivity,
        // force a strong pattern after enough time without successful pattern injection.
        if (rescueReady && stepsSincePatternInjection >= hardRescueSteps) {
            if (!injectRescuePattern()) {
                seedRandomCluster(clockModeEnabled ? 6 : 10, 4);
            }
            rescueCooldownSteps = Math.max(24, Math.round(effectiveTps * 12));
            return;
        }

        // If the world appears to be stuck for a long time (often tiny oscillators),
        // inject moving/high-energy patterns to break the loop.
        if (rescueReady && inactivityCounter >= rescueThresholdSteps) {
            if (!injectRescuePattern()) {
                seedRandomCluster(clockModeEnabled ? 5 : 8, 3);
            }
            rescueCooldownSteps = Math.max(24, Math.round(effectiveTps * 12));
            return;
        }

        if (surplusPressure > 0.85 && stagnation < 0.35) {
            return;
        }

        const microChanceBase = Math.min(0.90, 0.01 + deficitPressure * 0.58 + stagnation * 0.20);
        const microChance = microChanceBase * clockModeFactor * (1.0 - 0.70 * surplusPressure);
        if (Math.random() < microChance) {
            const microCount = Math.max(1, Math.round(1 + deficitPressure * 6 + stagnation * 4));
            seedRandomCluster(microCount, 2);
        }

        if (forced > 0.0 && Math.random() < forced) {
            const forcedCount = Math.max(1, Math.round(2 + forced * 10 + deficitPressure * 6));
            seedRandomCluster(forcedCount, 3);
        }

        const patternChanceBase = Math.min(0.70, 0.01 + deficitPressure * 0.55 + stagnation * 0.16 + cfgRarePatternChance * 0.08);
        const patternChance = patternChanceBase * clockModeFactor * (1.0 - 0.65 * surplusPressure);
        if (Math.random() < patternChance) {
            let selectedMode = cfgInjectorMode;
            if (deficitPressure > 0.55) {
                selectedMode = "Ships";
            } else if (cfgInjectorMode === "Mixed" && Math.random() < 0.80) {
                selectedMode = "Random Small";
            }
            if (!injectPattern("", false, selectedMode)) {
                seedRandomCluster(2 + Math.round(stagnation * 4 + deficitPressure * 4), 3);
            }
        }
    }

    function checkPreviewSeedRequest() {
        if (!renderRunning) {
            return;
        }
        if (clockModeEnabled) {
            return;
        }
        const token = cfgPreviewSeedRequest;
        if (!token.length || token === lastPreviewSeedRequest) {
            return;
        }
        lastPreviewSeedRequest = token;
        injectPattern(cfgPreviewPatternId, true, "Curated");
    }

    function checkReseedRequest() {
        const token = cfgReseedRequest;
        if (!token.length || token === lastReseedRequest) {
            return;
        }
        lastReseedRequest = token;
        requestReset("manual reseed");
    }

    function checkConfigRequests() {
        checkPreviewSeedRequest();
        checkReseedRequest();
    }

    function requestReset(reason) {
        logDebug("requestReset: " + reason + " viewport=" + viewportWidthPx + "x" + viewportHeightPx + " sim=" + simGridWidth + "x" + simGridHeight);
        pendingResetRequested = true;
        pendingResetReason = reason;
        if (canResetNow()) {
            resetTimer.reason = reason;
            resetTimer.restart();
        } else {
            logDebug("requestReset deferred (not ready): " + reason
                + " renderRunning=" + renderRunning
                + " scene=" + sceneVisible
                + " sim=" + simGridWidth + "x" + simGridHeight);
        }
    }

    function canResetNow() {
        return renderRunning
            && Number.isFinite(simGridWidth)
            && Number.isFinite(simGridHeight)
            && simGridWidth >= 16
            && simGridHeight >= 16
            && Number.isFinite(width)
            && Number.isFinite(height)
            && width > 8
            && height > 8;
    }

    function startupForceStepsFor(stage) {
        if (stage === "bootstrap") {
            return Math.max(2, Math.round(2 + startupSeedIntensity * 5));
        }
        if (stage === "health") {
            return Math.max(3, Math.round(3 + startupSeedIntensity * 5));
        }
        return Math.max(3, Math.round(4 + startupSeedIntensity * 8));
    }

    function startupHoldStepsFor(stage) {
        if (stage === "bootstrap") {
            return Math.round(4 + startupSeedIntensity * 8);
        }
        if (stage === "health") {
            return Math.round(5 + startupSeedIntensity * 8);
        }
        return Math.round(5 + startupSeedIntensity * 9);
    }

    function refreshStartupPending(includeWarmup) {
        const needsScatter = !startupScatterDone;
        const needsGosper = !startupGosperInjected;
        pendingStartupSeed = needsScatter || needsGosper || (includeWarmup && startupWarmupSteps > 0);
        return pendingStartupSeed;
    }

    function mergeStartupOutcome(scatterOk, gosperOk, includeWarmup) {
        startupScatterDone = startupScatterDone || !!scatterOk;
        startupGosperInjected = startupGosperInjected || !!gosperOk;
        return refreshStartupPending(includeWarmup);
    }

    function applyStartupBoost(forceSteps, holdSteps) {
        startupForceSeedSteps = Math.max(startupForceSeedSteps, Math.max(0, Math.round(forceSteps)));
        stampHoldSteps = Math.max(stampHoldSteps, Math.max(0, Math.round(holdSteps)));
        stepBudget = Math.max(stepBudget, 1.0);
    }

    function stopStartupRecoveryTimers() {
        bootstrapSeedTimer.stop();
        startupHealthTimer.stop();
        startupHealthChecksRemaining = 0;
    }

    function startStartupRecoveryTimers() {
        bootstrapSeedTimer.restart();
        startupHealthChecksRemaining = 6;
        startupHealthTimer.start();
    }

    function resetSimulation(reason) {
        if (!canResetNow()) {
            pendingResetRequested = true;
            pendingResetReason = reason;
            return;
        }
        pendingResetRequested = false;
        pendingResetReason = "";
        stopStartupRecoveryTimers();

        clearStampTexture();
        clearKillTexture();
        resetClockState(true);
        // Fixed-rate random bootstrap for both ping-pong targets.
        seedModeA = true;
        applyStampA = false;
        applyKillA = false;
        randomSeed = Math.random() * 100000.0;
        stateATexture.scheduleUpdate();

        seedModeB = true;
        applyStampB = false;
        applyKillB = false;
        // Keep seed mode alive long enough to avoid startup race conditions.
        startupForceSeedSteps = startupForceStepsFor("reset");
        startupWarmupSteps = 2;
        currentStateIsA = true;
        generation = 0;
        inactivityCounter = 0;
        stepsSincePatternInjection = 0;
        rescueCooldownSteps = 0;
        stepBudget = 1.0;
        aliveRatioEstimate = clamp01(startupFixedDensity);
        aliveRatioProbeValid = false;
        aliveRatioProbeInFlight = false;
        aliveRatioProbeSupported = true;
        aliveRatioProbeFailureStreak = 0;
        aliveRatioProbeSuccessCount = 0;
        aliveRatioProbeRequestId += 1;
        aliveRatioLastProbeGeneration = -1;
        aliveRatioSyntheticMomentum = clamp01(startupFixedDensity);
        lastStampedCellCount = 0;
        aliveRatioProbeTimeout.stop();
        startupScatterDone = seedStartupScatter();
        startupGosperInjected = injectGuaranteedStartupGosper();
        const kickstartOk = seedGuaranteedKickstart();
        if (kickstartOk) {
            startupScatterDone = true;
        }
        refreshStartupPending(true);
        simulationInitialized = true;

        if (!parsedRuleMasks.valid) {
            logDebug("invalid ruleString: " + cfgRuleString + " ; using B3/S23 fallback");
        }
        if (clockModeEnabled) {
            refreshClock(true);
        }

        stampHoldSteps = Math.max(stampHoldSteps, startupHoldStepsFor("reset"));
        requestAliveRatioProbe(true);
        stateATexture.scheduleUpdate();
        stateBTexture.scheduleUpdate();
        startStartupRecoveryTimers();
        logDebug("simulation reset: " + reason + " (" + simGridWidth + "x" + simGridHeight
            + ") intensity=" + startupSeedIntensity.toFixed(2)
            + " seedDensity=" + startupFixedDensity.toFixed(4));
    }

    function runOneStep() {
        if (!simulationInitialized) {
            return;
        }

        if (stampClearPending && stampHoldSteps <= 0) {
            clearStampTexture();
        }
        if (killClearPending && killHoldSteps <= 0) {
            clearKillTexture();
        }

        if (pendingStartupSeed) {
            if (!startupScatterDone) {
                startupScatterDone = seedStartupScatter() || seedRandomCluster(4, 2);
            }

            if (!startupGosperInjected) {
                startupGosperInjected = injectGuaranteedStartupGosper();
            }

            startupWarmupSteps = Math.max(0, startupWarmupSteps - 1);
            refreshStartupPending(true);
        }

        runClockTransitionStep();
        maintainClockDisplay();

        if (currentStateIsA) {
            if (startupForceSeedSteps > 0) {
                seedModeB = true;
                startupForceSeedSteps -= 1;
            } else {
                seedModeB = false;
            }
            applyStampB = stampActive;
            applyKillB = killActive;
            stateBTexture.scheduleUpdate();
            currentStateIsA = false;
        } else {
            if (startupForceSeedSteps > 0) {
                seedModeA = true;
                startupForceSeedSteps -= 1;
            } else {
                seedModeA = false;
            }
            applyStampA = stampActive;
            applyKillA = killActive;
            stateATexture.scheduleUpdate();
            currentStateIsA = true;
        }

        if (stampActive) {
            stampHoldSteps = Math.max(0, stampHoldSteps - 1);
            if (stampHoldSteps <= 0) {
                stampActive = false;
                stampClearPending = true;
            }
        }
        if (killActive) {
            killHoldSteps = Math.max(0, killHoldSteps - 1);
            if (killHoldSteps <= 0) {
                killActive = false;
                killClearPending = true;
            }
        }

        inactivityCounter += 1;
        stepsSincePatternInjection += 1;
        rescueCooldownSteps = Math.max(0, rescueCooldownSteps - 1);
        aliveRatioSyntheticMomentum = clamp01(
            aliveRatioSyntheticMomentum * (stampActive ? 0.985 : 0.975)
        );
        generation += 1;
    }

    Rectangle {
        anchors.fill: parent
        color: cfgBackgroundColor
    }

    ShaderEffect {
        id: statePassA
        visible: false
        width: simGridWidth
        height: simGridHeight

        property variant prevState: stateBTexture
        property variant stampTexture: stampTexture
        property variant killTexture: killTexture
        property vector2d texSize: Qt.vector2d(simGridWidth, simGridHeight)
        property real density: root.bootstrapSeedDensity
        property real randomSeed: root.randomSeed
        property real wrapEdges: cfgWrapEdges ? 1.0 : 0.0
        property real seedMode: root.seedModeA ? 1.0 : 0.0
        property real applyStamp: root.applyStampA ? 1.0 : 0.0
        property real applyKill: root.applyKillA ? 1.0 : 0.0
        property real bornMask: root.ruleBornMask
        property real surviveMask: root.ruleSurviveMask
        property vector4d clockRect: Qt.vector4d(clockRegionX, clockRegionY, clockRegionW, clockRegionH)
        property real clockEnabled: clockModeEnabled && clockRegionValid ? 1.0 : 0.0
        property real clockPad: clockBarrierPadding
        property real dyingDecayStep: 1.0 / Math.max(1, cfgDyingFadeTicks)
        property real _padding0: 0.0
        property real _padding1: 0.0

        fragmentShader: Qt.resolvedUrl("../shaders/life_step.frag.qsb")
    }

    ShaderEffectSource {
        id: stateATexture
        visible: false
        sourceItem: statePassA
        hideSource: true
        live: false
        recursive: false
        smooth: false
        textureSize: Qt.size(simGridWidth, simGridHeight)
    }

    ShaderEffect {
        id: statePassB
        visible: false
        width: simGridWidth
        height: simGridHeight

        property variant prevState: stateATexture
        property variant stampTexture: stampTexture
        property variant killTexture: killTexture
        property vector2d texSize: Qt.vector2d(simGridWidth, simGridHeight)
        property real density: root.bootstrapSeedDensity
        property real randomSeed: root.randomSeed
        property real wrapEdges: cfgWrapEdges ? 1.0 : 0.0
        property real seedMode: root.seedModeB ? 1.0 : 0.0
        property real applyStamp: root.applyStampB ? 1.0 : 0.0
        property real applyKill: root.applyKillB ? 1.0 : 0.0
        property real bornMask: root.ruleBornMask
        property real surviveMask: root.ruleSurviveMask
        property vector4d clockRect: Qt.vector4d(clockRegionX, clockRegionY, clockRegionW, clockRegionH)
        property real clockEnabled: clockModeEnabled && clockRegionValid ? 1.0 : 0.0
        property real clockPad: clockBarrierPadding
        property real dyingDecayStep: 1.0 / Math.max(1, cfgDyingFadeTicks)
        property real _padding0: 0.0
        property real _padding1: 0.0

        fragmentShader: Qt.resolvedUrl("../shaders/life_step.frag.qsb")
    }

    ShaderEffectSource {
        id: stateBTexture
        visible: false
        sourceItem: statePassB
        hideSource: true
        live: false
        recursive: false
        smooth: false
        textureSize: Qt.size(simGridWidth, simGridHeight)
    }

    Canvas {
        id: stampCanvas
        visible: false
        width: simGridWidth
        height: simGridHeight
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Cooperative
        contextType: "2d"

        property var pendingCells: []

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!pendingCells || pendingCells.length === 0) {
                return;
            }

            ctx.fillStyle = "#ffffff";
            for (let i = 0; i < pendingCells.length; ++i) {
                const c = pendingCells[i];
                ctx.fillRect(c.x, c.y, 1, 1);
            }
        }
    }

    ShaderEffectSource {
        id: stampTexture
        visible: false
        sourceItem: stampCanvas
        hideSource: true
        live: false
        recursive: false
        smooth: false
        textureSize: Qt.size(simGridWidth, simGridHeight)
    }

    Canvas {
        id: killCanvas
        visible: false
        width: simGridWidth
        height: simGridHeight
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Cooperative
        contextType: "2d"

        property var pendingCells: []

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!pendingCells || pendingCells.length === 0) {
                return;
            }

            ctx.fillStyle = "#ffffff";
            for (let i = 0; i < pendingCells.length; ++i) {
                const c = pendingCells[i];
                ctx.fillRect(c.x, c.y, 1, 1);
            }
        }
    }

    ShaderEffectSource {
        id: killTexture
        visible: false
        sourceItem: killCanvas
        hideSource: true
        live: false
        recursive: false
        smooth: false
        textureSize: Qt.size(simGridWidth, simGridHeight)
    }

    ShaderEffect {
        id: aliveRatioProbePass
        visible: false
        x: 0
        y: 0
        width: Math.max(8, aliveRatioProbeResolution)
        height: Math.max(8, aliveRatioProbeResolution)

        property variant stateTexture: currentStateIsA ? stateATexture : stateBTexture
        property vector2d texSize: Qt.vector2d(simGridWidth, simGridHeight)
        property real nonce: aliveRatioProbeNonce
        property real _padding0: 0.0
        property real _padding1: 0.0

        fragmentShader: Qt.resolvedUrl("../shaders/population_probe.frag.qsb")
    }

    ShaderEffectSource {
        id: aliveRatioProbeTexture
        visible: false
        sourceItem: aliveRatioProbePass
        hideSource: true
        live: false
        recursive: false
        smooth: false
        textureSize: Qt.size(Math.max(8, aliveRatioProbeResolution), Math.max(8, aliveRatioProbeResolution))
    }

    ShaderEffect {
        id: visualizePass
        visible: renderRunning && simulationInitialized
        anchors.fill: parent

        property variant stateTexture: currentStateIsA ? stateATexture : stateBTexture
        property variant prevStateTexture: currentStateIsA ? stateBTexture : stateATexture
        property color aliveColor: cfgAliveColor
        property color deadColor: cfgDeadColor
        property color backgroundColor: cfgBackgroundColor
        property real contrast: cfgPhotoSafe ? cfgSafeContrast : 1.0
        property real safeMode: cfgPhotoSafe ? 1.0 : 0.0
        property real safeSaturation: cfgSafeSaturation
        property real dyingPower: cfgDyingFadeEnabled ? 0.5 : 0.0
        property vector2d texSize: Qt.vector2d(simGridWidth, simGridHeight)
        property real cellShapeMode: cfgCellShape === "Go Board" ? 2.0 : (cfgCellShape === "Circle" ? 1.0 : 0.0)
        property real goBoardGrid: cfgCellShape === "Go Board" ? 1.0 : 0.0
        property real _padding0: 0.0
        property real _padding1: 0.0

        fragmentShader: Qt.resolvedUrl("../shaders/visualize.frag.qsb")
    }

    Rectangle {
        id: clockFaceOverlay
        visible: clockModeEnabled && clockRegionValid && renderRunning
        z: 14
        clip: true
        radius: 6
        color: root.renderPaletteActivity(0.0, 0.96)

        readonly property real pad: Math.max(2, clockBarrierPadding)
        x: Math.max(0, Math.floor(((clockRegionX - pad) / Math.max(1, simGridWidth)) * root.width))
        y: Math.max(0, Math.floor(((clockRegionY - pad) / Math.max(1, simGridHeight)) * root.height))
        width: Math.max(2, Math.floor(((clockRegionW + pad * 2) / Math.max(1, simGridWidth)) * root.width))
        height: Math.max(2, Math.floor(((clockRegionH + pad * 2) / Math.max(1, simGridHeight)) * root.height))

        Repeater {
            model: root.clockRenderCells && root.clockRenderCells.length ? root.clockRenderCells : root.clockCurrentCells
            delegate: Rectangle {
                required property var modelData

                readonly property real cellW: root.width / Math.max(1, root.simGridWidth)
                readonly property real cellH: root.height / Math.max(1, root.simGridHeight)
                readonly property real visualScale: root.clockOverlayScale()
                readonly property real pixelW: Math.max(1, Math.ceil(cellW * visualScale))
                readonly property real pixelH: Math.max(1, Math.ceil(cellH * visualScale))
                readonly property real baseX: (modelData.x / Math.max(1, root.simGridWidth)) * root.width
                readonly property real baseY: (modelData.y / Math.max(1, root.simGridHeight)) * root.height

                x: Math.floor(baseX + (cellW - pixelW) * 0.5) - clockFaceOverlay.x
                y: Math.floor(baseY + (cellH - pixelH) * 0.5) - clockFaceOverlay.y
                width: pixelW
                height: pixelH
                color: root.renderPaletteActivity(1.0, cfgPhotoSafe ? 0.88 : 1.0)
                radius: cfgCellShape === "Square" ? 0 : Math.min(width, height) * 0.5
            }
        }
    }

    Rectangle {
        id: clockBoundaryOverlay
        visible: clockModeEnabled && clockRegionValid && renderRunning
        z: 15
        color: "transparent"
        radius: 6

        readonly property real pad: Math.max(2, clockBarrierPadding)
        x: Math.max(0, Math.floor(((clockRegionX - pad) / Math.max(1, simGridWidth)) * root.width))
        y: Math.max(0, Math.floor(((clockRegionY - pad) / Math.max(1, simGridHeight)) * root.height))
        width: Math.max(2, Math.floor(((clockRegionW + pad * 2) / Math.max(1, simGridWidth)) * root.width))
        height: Math.max(2, Math.floor(((clockRegionH + pad * 2) / Math.max(1, simGridHeight)) * root.height))

        border.width: Math.max(1, clockBarrierThickness)
        border.color: root.renderPaletteActivity(0.72, 0.55)
    }

    MouseArea {
        id: seedMouseArea
        anchors.fill: parent
        z: 20
        enabled: cfgCursorDrawEnabled && renderRunning
        visible: cfgCursorDrawEnabled
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        propagateComposedEvents: true
        preventStealing: false
        property real pressX: 0
        property real pressY: 0
        property bool dragging: false

        onPressed: function (mouse) {
            pressX = mouse.x;
            pressY = mouse.y;
            dragging = false;
            mouse.accepted = true;
        }

        onPositionChanged: function (mouse) {
            if (!(mouse.buttons & Qt.LeftButton)) {
                return;
            }

            const dx = mouse.x - pressX;
            const dy = mouse.y - pressY;
            if (!dragging && (dx * dx + dy * dy) >= 16.0) {
                dragging = true;
                root.seedBrushAtScreen(pressX, pressY);
            }

            if (dragging) {
                root.seedBrushAtScreen(mouse.x, mouse.y);
            }
        }

        onReleased: function (mouse) {
            if (!dragging) {
                if (!root.stampPatternAtScreen("glider", mouse.x, mouse.y, true)) {
                    root.seedBrushAtScreen(mouse.x, mouse.y);
                }
            }
            dragging = false;
        }
    }

    QQC2.Label {
        visible: cfgDebug
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 12
        text: "Konway | gen=" + generation
            + " | sim=" + simGridWidth + "x" + simGridHeight
            + " | tps=" + Number(effectiveTps).toFixed(effectiveTps < 1.0 ? 2 : 1)
            + " | driverHz=" + effectiveStepRate
            + (cfgSyncFpsWithTps ? " (sync)" : " (manual)")
            + " | alive~" + Number(aliveRatioEstimate).toFixed(3)
        color: "#d8e4de"
        font.pixelSize: 12
        z: 5
    }

    Timer {
        id: stepTimer
        repeat: true
        running: renderRunning
        interval: Math.max(8, Math.round(1000 / effectiveStepRate))
        onTriggered: {
            const maxBatch = Math.max(1, cfgStepsPerFrame);
            const stepRate = Math.max(0.1, effectiveTps);
            const driverRate = Math.max(1, effectiveStepRate);
            stepBudget += stepRate / driverRate;

            let steps = Math.floor(stepBudget);
            if (steps > maxBatch) {
                steps = maxBatch;
            }

            if (steps <= 0) {
                return;
            }

            for (let i = 0; i < steps; ++i) {
                root.runOneStep();
            }
            stepBudget = Math.max(0.0, stepBudget - steps);
        }
    }

    Timer {
        id: injectorTimer
        repeat: true
        running: renderRunning && cfgAutoInject
        interval: effectiveInjectIntervalMs
        onTriggered: root.maybeInjectEnergy()
    }

    Timer {
        id: aliveRatioProbeTimer
        repeat: true
        running: renderRunning && simulationInitialized
        interval: Math.max(700, Math.round(effectiveInjectIntervalMs * 0.5))
        onTriggered: root.requestAliveRatioProbe(false)
    }

    Timer {
        id: aliveRatioProbeTimeout
        repeat: false
        interval: 900
        property int requestId: 0
        onTriggered: {
            if (!aliveRatioProbeInFlight || requestId !== aliveRatioProbeRequestId) {
                return;
            }
            aliveRatioProbeRequestId += 1;
            aliveRatioProbeInFlight = false;
            root.handleAliveRatioProbeFailure("timeout");
        }
    }

    Timer {
        id: clockTimer
        repeat: true
        running: renderRunning && clockModeEnabled
        interval: 1000
        onTriggered: root.refreshClock(false)
    }

    Timer {
        id: resetTimer
        repeat: false
        interval: 45
        property string reason: "unspecified"
        onTriggered: root.resetSimulation(reason)
    }

    Timer {
        id: resetPumpTimer
        repeat: true
        running: pendingResetRequested
        interval: 180
        onTriggered: {
            if (!pendingResetRequested || !renderRunning) {
                return;
            }
            if (!resetTimer.running) {
                resetTimer.reason = pendingResetReason.length > 0 ? pendingResetReason : "pump reset";
                if (canResetNow()) {
                    resetTimer.restart();
                }
            }
        }
    }

    Timer {
        id: bootstrapSeedTimer
        repeat: false
        interval: 700
        onTriggered: {
            if (!renderRunning || !simulationInitialized) {
                return;
            }
            // Second deterministic pass only when startup content is still too weak.
            const minExpected = Math.max(0.01, startupFixedDensity * 0.60);
            const needScatter = !startupScatterDone || aliveRatioEstimate < minExpected;
            const needGosper = !startupGosperInjected;
            if (!needScatter && !needGosper) {
                return;
            }
            const scatterOk = needScatter ? (seedStartupScatter() || seedGuaranteedKickstart()) : false;
            const gosperOk = needGosper ? injectGuaranteedStartupGosper() : false;
            mergeStartupOutcome(scatterOk, gosperOk, false);
            applyStartupBoost(startupForceStepsFor("bootstrap"), startupHoldStepsFor("bootstrap"));
        }
    }

    Timer {
        id: startupHealthTimer
        repeat: true
        interval: Math.max(700, Math.round(1800 / Math.max(1.0, effectiveTps)))
        onTriggered: {
            if (!renderRunning || !simulationInitialized) {
                return;
            }
            if (startupHealthChecksRemaining <= 0) {
                startupHealthTimer.stop();
                return;
            }
            startupHealthChecksRemaining -= 1;

            const ratio = estimateSyntheticAliveRatio();
            const minHealthy = Math.max(0.010, startupFixedDensity * 0.45);
            const minGeneration = Math.max(2, Math.round(2 + effectiveTps * 0.5));
            if (ratio >= minHealthy && generation > minGeneration) {
                startupHealthTimer.stop();
                return;
            }

            const kickOk = seedGuaranteedKickstart();
            const gosperOk = injectGuaranteedStartupGosper();
            mergeStartupOutcome(kickOk, gosperOk, false);
            applyStartupBoost(startupForceStepsFor("health"), startupHoldStepsFor("health"));
            logDebug("startup health rescue triggered ratio=" + ratio.toFixed(3)
                + " generation=" + generation);

            if (startupHealthChecksRemaining <= 0) {
                startupHealthTimer.stop();
            }
        }
    }

    onViewportWidthPxChanged: requestReset("size changed")
    onViewportHeightPxChanged: requestReset("size changed")

    onCfgCellSizeChanged: requestReset("cell size changed")
    onCfgWrapEdgesChanged: requestReset("topology changed")
    onCfgRuleStringChanged: requestReset("rule changed")
    onCfgInitialDensityChanged: requestReset("startup intensity changed")
    onCfgSimDownscaleChanged: requestReset("downscale changed")
    onCfgSyncFpsWithTpsChanged: stepBudget = 0.0
    onCfgMaxFpsChanged: stepBudget = 0.0
    onEffectiveSimDownscaleChanged: {
        if (effectiveSimDownscale > cfgSimDownscale) {
            logDebug("sim downscale safety clamp requested=" + cfgSimDownscale
                + " effective=" + effectiveSimDownscale
                + " budget=" + simCellBudget);
        }
    }
    onCfgTpsChanged: stepBudget = 0.0
    onCfgStepsPerFrameChanged: stepBudget = 0.0
    onCfgSafeUltraLowTpsEnabledChanged: stepBudget = 0.0
    onCfgSafeUltraLowTpsChanged: stepBudget = 0.0
    onCfgPhotoSafeChanged: stepBudget = 0.0
    onCfgDyingFadeTicksChanged: logDebug("dying fade ticks=" + cfgDyingFadeTicks)
    onCfgPreviewSeedRequestChanged: checkPreviewSeedRequest()
    onCfgReseedRequestChanged: checkReseedRequest()
    onCfgClockScaleChanged: {
        if (clockModeEnabled && simulationInitialized) {
            clearClockPatternFromSimulation();
            refreshClock(true);
        }
    }
    onCfgClockModeChanged: {
        requestReset(clockModeEnabled ? "clock mode enabled" : "clock mode disabled");
    }

    onRenderRunningChanged: {
        logDebug("renderRunning=" + renderRunning
            + " appActive=" + appActive
            + " windowVisible=" + windowVisible
            + " pauseWhenHidden=" + cfgPauseWhenHidden);
        stepBudget = 0.0;
        if (renderRunning) {
            if (pendingResetRequested) {
                resetTimer.reason = pendingResetReason.length > 0 ? pendingResetReason : "deferred reset";
                if (canResetNow()) {
                    resetTimer.restart();
                }
            } else if (!simulationInitialized) {
                requestReset("render started");
            } else if (clockModeEnabled) {
                refreshClock(true);
            }
            checkConfigRequests();
            requestAliveRatioProbe(true);
        }
    }

    onCfgDebugChanged: console.log("[konway] debug logging " + (cfgDebug ? "enabled" : "disabled"))

    Component.onCompleted: {
        loadPatternIndex();
        requestReset("startup");
    }

    Component.onDestruction: {
        stopStartupRecoveryTimers();
        stepTimer.running = false;
        injectorTimer.running = false;
        aliveRatioProbeTimer.running = false;
        clockTimer.running = false;
        resetTimer.running = false;
        aliveRatioProbeTimeout.running = false;
    }
}
