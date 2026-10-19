import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "components"
import "../patterns/patternData.js" as PatternData

Kirigami.ScrollablePage {
    id: page
    property var cfg

    title: i18n("Activity")

    property var allPatterns: []
    property var visiblePatterns: []
    property string searchText: ""
    property string categoryFilter: ""

    readonly property bool adaptive: cfg.cfg_injectionStyle !== "Classic"
    readonly property var categoryNames: ({
        "gliders": i18n("Gliders"),
        "spaceships": i18n("Spaceships"),
        "methuselahs": i18n("Methuselahs"),
        "oscillators": i18n("Oscillators"),
        "guns": i18n("Guns"),
        "still_lifes": i18n("Still lifes")
    })
    readonly property var categoryHints: ({
        "gliders": i18n("Small travellers"),
        "spaceships": i18n("Larger travellers"),
        "methuselahs": i18n("Long-lived growth seeds"),
        "oscillators": i18n("Blinkers and friends (quiet)"),
        "guns": i18n("Endless glider streams (rare)"),
        "still_lifes": i18n("Static decoration (quiet)")
    })
    readonly property var categoryIds: ["gliders", "spaceships", "methuselahs", "oscillators", "guns", "still_lifes"]

    readonly property var categoryFilterModel: [i18n("All categories")].concat(categoryIds.map(function (id) { return categoryNames[id]; }))

    function livelinessName(v) {
        if (v < 0.15) {
            return i18n("Serene");
        }
        if (v < 0.40) {
            return i18n("Calm");
        }
        if (v < 0.65) {
            return i18n("Moderate");
        }
        if (v < 0.85) {
            return i18n("Busy");
        }
        return i18n("Lively");
    }

    function parseCategories() {
        const categories = (cfg.cfg_enabledCategories || "").split(",").map(s => s.trim()).filter(s => s.length > 0);
        return new Set(categories);
    }

    function isCategoryEnabled(cat) {
        return parseCategories().has(cat);
    }

    function setCategoryEnabled(cat, enabled) {
        const categories = parseCategories();
        if (enabled) {
            categories.add(cat);
        } else {
            categories.delete(cat);
        }
        cfg.cfg_enabledCategories = Array.from(categories).join(",");
    }

    function loadIndex() {
        if (!PatternData || !PatternData.patternIndex || !PatternData.patternIndex.patterns) {
            allPatterns = [];
        } else {
            allPatterns = (PatternData.patternIndex.patterns || []).slice().sort((a, b) => {
                return String(a.name).localeCompare(String(b.name));
            });
        }
        applyFilter();
    }

    function applyFilter() {
        const needle = searchText.trim().toLowerCase();
        visiblePatterns = allPatterns.filter(function (p) {
            if (categoryFilter.length > 0 && p.category !== categoryFilter) {
                return false;
            }
            return needle.length === 0 || String(p.name).toLowerCase().indexOf(needle) >= 0;
        });
    }

    function requestPreview(patternId) {
        cfg.cfg_previewPatternId = patternId;
        cfg.cfg_previewSeedRequest = String(Date.now());
    }

    Component.onCompleted: loadIndex()

    Kirigami.FormLayout {
        width: parent.width

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Keeping it alive")
        }

        QQC2.Switch {
            Kirigami.FormData.label: i18n("Auto-injection:")
            text: checked ? i18n("On") : i18n("Off")
            checked: cfg.cfg_autoInject
            onToggled: cfg.cfg_autoInject = checked
        }

        Hint {
            text: i18n("Adds new life when the world gets dull. Off = strictly deterministic.")
        }

        Segmented {
            Kirigami.FormData.label: i18n("Style:")
            enabled: cfg.cfg_autoInject
            options: [
                { "id": "Adaptive", "label": i18n("Adaptive"), "icon": "view-statistics" },
                { "id": "Classic", "label": i18n("Classic"), "icon": "chronometer" }
            ]
            current: page.adaptive ? "Adaptive" : "Classic"
            onPicked: function (id) { cfg.cfg_injectionStyle = id; }
        }

        Hint {
            text: page.adaptive
                  ? i18n("Finds quiet areas of the screen and fills them: growth seeds, travelling gliders, and gliders aimed at stale clusters.")
                  : i18n("Original timer-based behaviour: random seeds and rescue patterns at a fixed interval, placed without looking at the screen.")
        }

        SliderRow {
            visible: page.adaptive
            enabled: cfg.cfg_autoInject
            Kirigami.FormData.label: i18n("Liveliness:")
            from: 0.0
            to: 1.0
            stepSize: 0.05
            value: cfg.cfg_liveliness
            formatter: function (v) { return page.livelinessName(v); }
            onValueEdited: function (v) { cfg.cfg_liveliness = v; }
        }


        SliderRow {
            visible: !page.adaptive
            enabled: cfg.cfg_autoInject
            Kirigami.FormData.label: i18n("Check every:")
            from: 500
            to: 12000
            stepSize: 100
            value: Math.max(500, Math.min(12000, cfg.cfg_injectIntervalMs))
            formatter: function (v) { return Number(v / 1000).toFixed(1) + " s"; }
            onValueEdited: function (v) { cfg.cfg_injectIntervalMs = Math.round(v / 100) * 100; }
        }

        SliderRow {
            visible: !page.adaptive
            enabled: cfg.cfg_autoInject
            Kirigami.FormData.label: i18n("Random seeding:")
            from: 0.0
            to: 0.30
            value: cfg.cfg_forcedInjectChance
            onValueEdited: function (v) { cfg.cfg_forcedInjectChance = v; }
        }


        SliderRow {
            visible: !page.adaptive
            enabled: cfg.cfg_autoInject
            Kirigami.FormData.label: i18n("Minimum alive:")
            from: 0.05
            to: 0.70
            value: cfg.cfg_minAliveRatio
            onValueEdited: function (v) { cfg.cfg_minAliveRatio = v; }
        }


        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Mouse")
        }

        QQC2.Switch {
            Kirigami.FormData.label: i18n("Draw with mouse:")
            text: checked ? i18n("On") : i18n("Off")
            checked: cfg.cfg_cursorDrawEnabled
            onToggled: cfg.cfg_cursorDrawEnabled = checked
        }


        RowLayout {
            Kirigami.FormData.label: i18n("Brush size:")
            enabled: cfg.cfg_cursorDrawEnabled
            QQC2.SpinBox {
                from: 1
                to: 12
                value: cfg.cfg_cursorBrushSize
                editable: true
                onValueModified: cfg.cfg_cursorBrushSize = value
            }
            QQC2.Label {
                text: i18n("cells")
                color: Kirigami.Theme.disabledTextColor
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("What can appear")
        }

        GridLayout {
            Kirigami.FormData.label: i18n("Categories:")
            columns: 3
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: 0

            Repeater {
                model: page.categoryIds
                delegate: QQC2.CheckBox {
                    required property string modelData
                    text: page.categoryNames[modelData]
                    checked: page.isCategoryEnabled(modelData)
                    onToggled: page.setCategoryEnabled(modelData, checked)
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    QQC2.ToolTip.text: page.categoryHints[modelData]
                }
            }
        }


        QQC2.ComboBox {
            visible: cfg.showAdvanced && !page.adaptive
            Kirigami.FormData.label: i18n("Injector mode:")
            model: ["Curated", "Random Small", "Methuselah", "Ships", "Mixed"]
            currentIndex: Math.max(0, model.indexOf(cfg.cfg_injectorMode))
            onActivated: cfg.cfg_injectorMode = model[currentIndex]
        }


        SliderRow {
            visible: cfg.showAdvanced && !page.adaptive
            Kirigami.FormData.label: i18n("Rare patterns:")
            from: 0.0
            to: 0.5
            value: cfg.cfg_rarePatternChance
            onValueEdited: function (v) { cfg.cfg_rarePatternChance = v; }
        }

        RowLayout {
            visible: cfg.showAdvanced
            Kirigami.FormData.label: i18n("Max pattern size:")
            QQC2.SpinBox {
                from: 8
                to: 1024
                value: cfg.cfg_maxPatternSize
                editable: true
                onValueModified: cfg.cfg_maxPatternSize = value
            }
            QQC2.Label {
                text: i18n("cells")
                color: Kirigami.Theme.disabledTextColor
            }
        }

        QQC2.CheckBox {
            visible: cfg.showAdvanced
            text: i18n("Allow stamps above the max size")
            checked: cfg.cfg_allowLargePatterns
            onToggled: cfg.cfg_allowLargePatterns = checked
        }

        Kirigami.Separator {
            visible: cfg.showAdvanced
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Pattern library (%1)", page.allPatterns.length)
        }

        RowLayout {
            visible: cfg.showAdvanced
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.SearchField {
                Layout.fillWidth: true
                Layout.maximumWidth: Kirigami.Units.gridUnit * 16
                placeholderText: i18n("Search patterns…")
                onTextChanged: {
                    page.searchText = text;
                    page.applyFilter();
                }
            }

            QQC2.ComboBox {
                model: page.categoryFilterModel
                onActivated: function (index) {
                    page.categoryFilter = index === 0 ? "" : page.categoryIds[index - 1];
                    page.applyFilter();
                }
            }
        }

        Rectangle {
            visible: cfg.showAdvanced
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 9
            color: "transparent"
            radius: 6
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.2)
            clip: true

            ListView {
                anchors.fill: parent
                anchors.margins: 1
                model: page.visiblePatterns
                boundsBehavior: Flickable.StopAtBounds
                QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

                delegate: QQC2.ItemDelegate {
                    id: delegateRoot
                    required property var modelData
                    width: ListView.view.width
                    highlighted: cfg.cfg_previewPatternId === modelData.id
                    onClicked: cfg.cfg_previewPatternId = modelData.id

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: delegateRoot.modelData.name
                            elide: Text.ElideRight
                        }

                        QQC2.Label {
                            text: page.categoryNames[delegateRoot.modelData.category] || delegateRoot.modelData.category
                            font: Kirigami.Theme.smallFont
                            color: Kirigami.Theme.disabledTextColor
                        }

                        QQC2.Label {
                            Layout.minimumWidth: Kirigami.Units.gridUnit * 3
                            horizontalAlignment: Text.AlignRight
                            text: delegateRoot.modelData.bboxW + "×" + delegateRoot.modelData.bboxH
                            font.family: "monospace"
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.disabledTextColor
                        }

                        QQC2.Button {
                            text: i18n("Preview")
                            icon.name: "media-playback-start"
                            onClicked: page.requestPreview(delegateRoot.modelData.id)
                        }
                    }
                }

                QQC2.Label {
                    anchors.centerIn: parent
                    visible: page.visiblePatterns.length === 0
                    text: i18n("No patterns match")
                    color: Kirigami.Theme.disabledTextColor
                }
            }
        }

    }
}
