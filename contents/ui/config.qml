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
    // Lets tests and tooling jump to a tab.
    property alias currentTabIndex: tabBar.currentIndex

    property string cfg_preset
    property bool cfg_debugLogging
    property string cfg_reseedRequest
    property string cfg_clockMode
    property double cfg_clockScale
    property string cfg_clockHourFormat
    property bool cfg_clockShowAmPm
    property bool cfg_clockLeadingZero
    property bool cfg_clockWhilePaused

    property int cfg_cellSize
    property int cfg_tps
    property int cfg_stepsPerFrame
    property bool cfg_wrapEdges
    property string cfg_ruleString
    property double cfg_initialDensity

    property bool cfg_autoInject
    property string cfg_injectionStyle
    property double cfg_liveliness
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
    property int cfg_dyingFadeTicks

    property bool cfg_chillMode
    property double cfg_chillBreathing
    property bool cfg_chillSoftFade
    property bool cfg_chillGentleInjection
    property bool cfg_chillDimEnabled
    property double cfg_chillDimLevel
    property int cfg_chillDimStart
    property int cfg_chillDimEnd

    property bool cfg_photosensitiveSafe
    property double cfg_safeContrast
    property double cfg_safeSaturation
    property bool cfg_safeUltraLowTpsEnabled
    property double cfg_safeUltraLowTps

    property int cfg_simDownscale
    property bool cfg_syncFpsWithTps
    property int cfg_maxFps
    property bool cfg_pauseWhenHidden

    // Shared by every tab: reveals the rarely needed controls.
    property bool showAdvanced: false

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

    readonly property var tabs: [
        { "source": "configGeneral.qml", "label": i18n("General"), "icon": "configure" },
        { "source": "configSimulation.qml", "label": i18n("Simulation"), "icon": "applications-science" },
        { "source": "configActivity.qml", "label": i18n("Activity"), "icon": "games-config-board" },
        { "source": "configAppearance.qml", "label": i18n("Appearance"), "icon": "preferences-desktop-color" },
        { "source": "configChill.qml", "label": i18n("Zen"), "icon": "weather-clear-night" },
        { "source": "configPerformance.qml", "label": i18n("Performance"), "icon": "speedometer" },
        { "source": "configSafety.qml", "label": i18n("Safety"), "icon": "security-high" }
    ]

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
        cfg_liveliness = preset.liveliness;
        cfg_chillMode = preset.chillMode;
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

    function presetTagline(name) {
        if (name === "Zen") {
            return i18n("Slow, soft and calm. Turns on Zen mode.");
        }
        if (name === "Quiet") {
            return i18n("Minimal motion, light on resources.");
        }
        if (name === "Balanced") {
            return i18n("Steady activity for everyday use.");
        }
        if (name === "Lively") {
            return i18n("Faster ticks and a busier screen.");
        }
        if (name === "Showcase") {
            return i18n("Dense, fast and eye-catching.");
        }
        return "";
    }

    function presetIcon(name) {
        if (name === "Zen") {
            return "weather-clear-night";
        }
        if (name === "Quiet") {
            return "audio-volume-low";
        }
        if (name === "Balanced") {
            return "games-config-board";
        }
        if (name === "Lively") {
            return "media-playback-start";
        }
        if (name === "Showcase") {
            return "starred-symbolic";
        }
        return "configure";
    }

    function presetDescription(name) {
        if (name === "Zen") {
            return i18n("Relaxing profile: slow ticks, soft contrast, gentle injections, long fades and a gently breathing tempo.");
        }
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
        cfg_reseedRequest = defaults.reseedRequest;
        cfg_clockMode = defaults.clockMode;
        cfg_clockHourFormat = defaults.clockHourFormat;
        cfg_clockShowAmPm = defaults.clockShowAmPm;
        cfg_clockLeadingZero = defaults.clockLeadingZero;
        cfg_clockWhilePaused = defaults.clockWhilePaused;
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

    function resetActivityDefaults() {
        cfg_autoInject = defaults.autoInject;
        cfg_injectionStyle = defaults.injectionStyle;
        cfg_liveliness = defaults.liveliness;
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
        cfg_dyingFadeTicks = defaults.dyingFadeTicks;
    }

    function resetChillDefaults() {
        cfg_chillMode = defaults.chillMode;
        cfg_chillBreathing = defaults.chillBreathing;
        cfg_chillSoftFade = defaults.chillSoftFade;
        cfg_chillGentleInjection = defaults.chillGentleInjection;
        cfg_chillDimEnabled = defaults.chillDimEnabled;
        cfg_chillDimLevel = defaults.chillDimLevel;
        cfg_chillDimStart = defaults.chillDimStart;
        cfg_chillDimEnd = defaults.chillDimEnd;
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
        resetActivityDefaults();
        resetAppearanceDefaults();
        resetChillDefaults();
        resetPerformanceDefaults();
        resetSafetyDefaults();
    }

    function resetCurrentTab() {
        const source = tabs[tabBar.currentIndex].source;
        if (source === "configGeneral.qml") {
            resetGeneralDefaults();
        } else if (source === "configSimulation.qml") {
            resetSimulationDefaults();
        } else if (source === "configActivity.qml") {
            resetActivityDefaults();
        } else if (source === "configAppearance.qml") {
            resetAppearanceDefaults();
        } else if (source === "configChill.qml") {
            resetChillDefaults();
        } else if (source === "configPerformance.qml") {
            resetPerformanceDefaults();
        } else if (source === "configSafety.qml") {
            resetSafetyDefaults();
        }
    }

    onCfg_cellSizeChanged: markPresetCustom()
    onCfg_tpsChanged: markPresetCustom()
    onCfg_stepsPerFrameChanged: markPresetCustom()
    onCfg_initialDensityChanged: markPresetCustom()
    onCfg_injectIntervalMsChanged: markPresetCustom()
    onCfg_minAliveRatioChanged: markPresetCustom()
    onCfg_rarePatternChanceChanged: markPresetCustom()
    onCfg_forcedInjectChanceChanged: markPresetCustom()
    onCfg_livelinessChanged: markPresetCustom()
    onCfg_chillModeChanged: markPresetCustom()
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

    // ---- Tab strip ------------------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        QQC2.TabBar {
            id: tabBar
            Layout.fillWidth: true

            Repeater {
                model: root.tabs
                delegate: QQC2.TabButton {
                    required property var modelData
                    text: modelData.label
                    icon.name: modelData.icon
                    display: root.width < Kirigami.Units.gridUnit * 56 ? QQC2.AbstractButton.IconOnly : QQC2.AbstractButton.TextBesideIcon
                    width: implicitWidth
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: modelData.label
                }
            }
        }

        QQC2.Switch {
            text: i18n("Advanced")
            checked: root.showAdvanced
            onToggled: root.showAdvanced = checked
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            QQC2.ToolTip.text: i18n("Show rarely needed controls on every tab")
        }
    }

    Loader {
        id: pageLoader
        Layout.fillWidth: true
        Layout.fillHeight: true

        function loadCurrentPage() {
            setSource(root.tabs[tabBar.currentIndex].source, { "cfg": root });
        }

        Component.onCompleted: loadCurrentPage()
    }

    Connections {
        target: tabBar
        function onCurrentIndexChanged() {
            pageLoader.loadCurrentPage();
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    // ---- Footer ---------------------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            Layout.fillWidth: true
            visible: currentConwayQuote.length > 0 && root.width > Kirigami.Units.gridUnit * 36
            text: "“" + currentConwayQuote + "” — John Horton Conway"
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.italic: true
            color: Kirigami.Theme.disabledTextColor
        }

        QQC2.Button {
            text: root.width < Kirigami.Units.gridUnit * 30 ? "" : i18n("Reset This Tab")
            icon.name: "edit-undo"
            onClicked: root.resetCurrentTab()
        }

        QQC2.Button {
            text: i18n("Reset All…")
            icon.name: "edit-reset"
            onClicked: resetAllDialog.open()
        }
    }

    Kirigami.PromptDialog {
        id: resetAllDialog
        title: i18n("Reset all settings?")
        subtitle: i18n("Every Konway option returns to its default value. This only takes effect when you press Apply.")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: root.resetAllDefaults()
    }
}
