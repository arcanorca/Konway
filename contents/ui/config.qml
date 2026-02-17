import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtCore
import org.kde.kirigami as Kirigami
import "lib/presets.js" as Presets
import "lib/conwayQuotes.js" as QuoteData

ColumnLayout {
    id: root
    spacing: Kirigami.Units.smallSpacing

    property var configDialog
    property var wallpaperConfiguration
    property var parentLayout

    property bool cfg_enabled
    property string cfg_preset
    property bool cfg_debugLogging
    property string cfg_reseedRequest
    property string cfg_clockMode
    property double cfg_clockScale

    property int cfg_cellSize
    property int cfg_tps
    property int cfg_stepsPerFrame
    property bool cfg_wrapEdges
    property string cfg_ruleString
    property double cfg_initialDensity

    property bool cfg_autoInject
    property int cfg_injectIntervalMs
    property double cfg_minAliveRatio
    property double cfg_rarePatternChance
    property double cfg_forcedInjectChance

    property string cfg_injectorMode
    property string cfg_categoryWeights
    property string cfg_enabledCategories
    property int cfg_maxPatternSize
    property bool cfg_allowLargePatterns
    property string cfg_previewPatternId
    property string cfg_previewSeedRequest
    property bool cfg_cursorDrawEnabled
    property int cfg_cursorBrushSize

    property string cfg_palette
    property color cfg_aliveColor
    property color cfg_deadColor
    property color cfg_backgroundColor
    property string cfg_cellShape
    property bool cfg_dyingFadeEnabled

    property bool cfg_photosensitiveSafe
    property double cfg_safeContrast
    property double cfg_safeSaturation
    property bool cfg_safeUltraLowTpsEnabled
    property double cfg_safeUltraLowTps

    property int cfg_simDownscale
    property bool cfg_syncFpsWithTps
    property int cfg_maxFps
    property bool cfg_pauseWhenHidden
    property bool presetApplyInProgress: false
    property bool presetTrackingReady: false
    property string currentConwayQuote: ""

    Settings {
        id: quoteState
        category: "KonwaySettings"
        property int nextQuoteIndex: 0
    }

    readonly property var conwayQuotes: QuoteData.quotes
    readonly property var defaults: Presets.defaults
    readonly property var practicalPresetOrder: Presets.practicalPresetOrder
    readonly property var practicalPresets: Presets.practicalPresets

    function triggerReseed() {
        const token = String(Date.now()) + "-" + String(Math.floor(Math.random() * 1000000));
        cfg_reseedRequest = token;
        if (wallpaperConfiguration) {
            wallpaperConfiguration["reseedRequest"] = token;
        }
    }

    function applyPracticalPreset(name) {
        const preset = practicalPresets[name];
        if (!preset) {
            return;
        }

        presetApplyInProgress = true;
        cfg_preset = name;
        cfg_cellSize = preset.cellSize;
        cfg_tps = preset.tps;
        cfg_stepsPerFrame = preset.stepsPerFrame;
        cfg_initialDensity = preset.initialDensity;
        cfg_autoInject = true;
        cfg_injectIntervalMs = preset.injectIntervalMs;
        cfg_minAliveRatio = preset.minAliveRatio;
        cfg_rarePatternChance = preset.rarePatternChance;
        cfg_forcedInjectChance = preset.forcedInjectChance;
        cfg_simDownscale = preset.simDownscale;
        cfg_syncFpsWithTps = preset.syncFpsWithTps;
        cfg_maxFps = preset.maxFps;
        cfg_pauseWhenHidden = preset.pauseWhenHidden;
        cfg_photosensitiveSafe = preset.photosensitiveSafe;
        cfg_safeContrast = preset.safeContrast;
        cfg_safeSaturation = preset.safeSaturation;
        cfg_safeUltraLowTpsEnabled = preset.safeUltraLowTpsEnabled;
        cfg_safeUltraLowTps = preset.safeUltraLowTps;
        cfg_clockScale = preset.clockScale;
        presetApplyInProgress = false;
    }

    function presetDescription(name) {
        if (name === "Quiet") {
            return i18n("Lower motion profile: reduced TPS, lighter injection, and Pause when hidden enabled.");
        }
        if (name === "Balanced") {
            return i18n("Middle-ground profile: balanced speed and activity.");
        }
        if (name === "Lively") {
            return i18n("Higher-energy profile: faster ticks with more frequent activity updates.");
        }
        if (name === "Showcase") {
            return i18n("Maximum visual profile: high simulation speed and denser active scenes.");
        }
        return i18n("Custom profile: manual values are active.");
    }

    function markPresetCustom() {
        if (!presetTrackingReady) {
            return;
        }
        if (!presetApplyInProgress && cfg_preset !== "Custom") {
            cfg_preset = "Custom";
        }
    }

    function rotateConwayQuote() {
        if (!conwayQuotes || conwayQuotes.length === 0) {
            currentConwayQuote = "";
            return;
        }
        let index = Number(quoteState.nextQuoteIndex);
        if (!isFinite(index) || index < 0) {
            index = 0;
        }
        index = Math.floor(index) % conwayQuotes.length;
        currentConwayQuote = conwayQuotes[index];
        quoteState.nextQuoteIndex = (index + 1) % conwayQuotes.length;
    }

    function resetGeneralDefaults() {
        cfg_enabled = defaults.enabled;
        cfg_reseedRequest = defaults.reseedRequest;
        cfg_clockMode = defaults.clockMode;
        applyPracticalPreset(defaults.preset);
    }

    function resetSimulationDefaults() {
        cfg_cellSize = defaults.cellSize;
        cfg_tps = defaults.tps;
        cfg_stepsPerFrame = defaults.stepsPerFrame;
        cfg_wrapEdges = defaults.wrapEdges;
        cfg_ruleString = defaults.ruleString;
        cfg_initialDensity = defaults.initialDensity;
        cfg_debugLogging = defaults.debugLogging;
    }

    function resetPatternsDefaults() {
        cfg_autoInject = defaults.autoInject;
        cfg_injectIntervalMs = defaults.injectIntervalMs;
        cfg_minAliveRatio = defaults.minAliveRatio;
        cfg_rarePatternChance = defaults.rarePatternChance;
        cfg_forcedInjectChance = defaults.forcedInjectChance;
        cfg_injectorMode = defaults.injectorMode;
        cfg_categoryWeights = defaults.categoryWeights;
        cfg_enabledCategories = defaults.enabledCategories;
        cfg_maxPatternSize = defaults.maxPatternSize;
        cfg_allowLargePatterns = defaults.allowLargePatterns;
        cfg_previewPatternId = defaults.previewPatternId;
        cfg_cursorDrawEnabled = defaults.cursorDrawEnabled;
        cfg_cursorBrushSize = defaults.cursorBrushSize;
    }

    function resetAppearanceDefaults() {
        cfg_palette = defaults.palette;
        cfg_aliveColor = defaults.aliveColor;
        cfg_deadColor = defaults.deadColor;
        cfg_backgroundColor = defaults.backgroundColor;
        cfg_cellShape = defaults.cellShape;
        cfg_dyingFadeEnabled = defaults.dyingFadeEnabled;
    }

    function resetPerformanceDefaults() {
        cfg_simDownscale = defaults.simDownscale;
        cfg_syncFpsWithTps = defaults.syncFpsWithTps;
        cfg_maxFps = defaults.maxFps;
        cfg_stepsPerFrame = defaults.stepsPerFrame;
        cfg_pauseWhenHidden = defaults.pauseWhenHidden;
    }

    function resetSafetyDefaults() {
        cfg_photosensitiveSafe = defaults.photosensitiveSafe;
        cfg_safeContrast = defaults.safeContrast;
        cfg_safeSaturation = defaults.safeSaturation;
        cfg_safeUltraLowTpsEnabled = defaults.safeUltraLowTpsEnabled;
        cfg_safeUltraLowTps = defaults.safeUltraLowTps;
    }

    function resetAllDefaults() {
        resetGeneralDefaults();
        resetSimulationDefaults();
        resetPatternsDefaults();
        resetAppearanceDefaults();
        resetPerformanceDefaults();
        resetSafetyDefaults();
    }

    onCfg_cellSizeChanged: markPresetCustom()
    onCfg_tpsChanged: markPresetCustom()
    onCfg_stepsPerFrameChanged: markPresetCustom()
    onCfg_initialDensityChanged: markPresetCustom()
    onCfg_injectIntervalMsChanged: markPresetCustom()
    onCfg_minAliveRatioChanged: markPresetCustom()
    onCfg_rarePatternChanceChanged: markPresetCustom()
    onCfg_forcedInjectChanceChanged: markPresetCustom()
    onCfg_simDownscaleChanged: markPresetCustom()
    onCfg_syncFpsWithTpsChanged: markPresetCustom()
    onCfg_maxFpsChanged: markPresetCustom()
    onCfg_pauseWhenHiddenChanged: markPresetCustom()
    onCfg_photosensitiveSafeChanged: markPresetCustom()
    onCfg_safeContrastChanged: markPresetCustom()
    onCfg_safeSaturationChanged: markPresetCustom()
    onCfg_safeUltraLowTpsEnabledChanged: markPresetCustom()
    onCfg_safeUltraLowTpsChanged: markPresetCustom()
    onCfg_clockScaleChanged: markPresetCustom()

    Component.onCompleted: {
        rotateConwayQuote();
        presetTrackingReady = true;
    }

    readonly property var pageSources: [
        "configGeneral.qml",
        "configSimulation.qml",
        "configPatterns.qml",
        "configAppearance.qml",
        "configPerformance.qml",
        "configSafety.qml"
    ]

    QQC2.Frame {
        Layout.fillWidth: true
        visible: currentConwayQuote.length > 0

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: i18n("John Horton Conway")
                font.bold: true
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: "\"" + currentConwayQuote + "\""
                wrapMode: Text.WordWrap
                font.italic: true
            }
        }
    }

    QQC2.TabBar {
        id: tabs
        Layout.fillWidth: true

        QQC2.TabButton { text: i18n("General") }
        QQC2.TabButton { text: i18n("Simulation") }
        QQC2.TabButton { text: i18n("Patterns") }
        QQC2.TabButton { text: i18n("Appearance") }
        QQC2.TabButton { text: i18n("Performance") }
        QQC2.TabButton { text: i18n("Safety") }
    }

    Loader {
        id: pageLoader
        Layout.fillWidth: true
        Layout.fillHeight: true
        
        function loadCurrentPage() {
            setSource(pageSources[tabs.currentIndex], { "cfg": root });
        }

        Component.onCompleted: loadCurrentPage()
    }

    Connections {
        target: tabs
        function onCurrentIndexChanged() {
            pageLoader.loadCurrentPage();
        }
    }
}
