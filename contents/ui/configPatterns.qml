import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../patterns/patternData.js" as PatternData

Kirigami.ScrollablePage {
    id: page
    property var cfg

    title: i18n("Patterns")

    property var allPatterns: []
    property bool showAdvanced: false
    property int intervalMinMs: 500
    property int intervalMaxMs: 12000

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
            return;
        }
        allPatterns = (PatternData.patternIndex.patterns || []).slice().sort((a, b) => {
            return String(a.name).localeCompare(String(b.name));
        });
    }

    function requestPreview(patternId) {
        cfg.cfg_previewPatternId = patternId;
        cfg.cfg_previewSeedRequest = String(Date.now());
    }

    Component.onCompleted: loadIndex()

    Kirigami.FormLayout {
        width: parent.width

        Kirigami.InlineMessage {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18n("Pattern injection prevents low-activity collapse and keeps the world evolving.")
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Auto inject:")
            text: i18n("Enable automatic activity injection")
            checked: cfg.cfg_autoInject
            onToggled: cfg.cfg_autoInject = checked
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Inject interval:")
            enabled: cfg.cfg_autoInject

            QQC2.Slider {
                id: injectIntervalSlider
                Layout.fillWidth: true
                from: page.intervalMinMs
                to: page.intervalMaxMs
                stepSize: 100
                value: Math.max(from, Math.min(to, cfg.cfg_injectIntervalMs))
                onMoved: cfg.cfg_injectIntervalMs = Math.round(value / 100) * 100
            }

            QQC2.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                horizontalAlignment: Text.AlignRight
                text: Number(injectIntervalSlider.value / 1000).toFixed(1) + " s"
                font.family: "monospace"
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Interval info:")
            text: i18n("Check period for activity recovery and pattern insertion (0.5s to 12.0s).")
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Random seeding:")

            QQC2.Slider {
                id: randomSeedSlider
                Layout.fillWidth: true
                from: 0.0
                to: 0.30
                value: cfg.cfg_forcedInjectChance
                onMoved: cfg.cfg_forcedInjectChance = value
            }

            QQC2.Label {
                text: Number(randomSeedSlider.value).toFixed(2)
                font.family: "monospace"
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("What it does:")
            text: i18n("Adds random micro-seeds each injection cycle. 0.00 limits injection to activity-recovery logic.")
            wrapMode: Text.WordWrap
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Mouse seeding:")
            text: i18n("Enable left click glider and left drag brush")
            checked: cfg.cfg_cursorDrawEnabled
            onToggled: cfg.cfg_cursorDrawEnabled = checked
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Brush size:")
            from: 1
            to: 12
            value: cfg.cfg_cursorBrushSize
            enabled: cfg.cfg_cursorDrawEnabled
            editable: true
            onValueModified: cfg.cfg_cursorBrushSize = value
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Advanced:")
            text: i18n("Show advanced pattern controls")
            checked: page.showAdvanced
            onToggled: page.showAdvanced = checked
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Injector mode:")
            visible: page.showAdvanced
            model: ["Curated", "Random Small", "Methuselah", "Ships", "Mixed"]
            currentIndex: Math.max(0, model.indexOf(cfg.cfg_injectorMode))
            onActivated: cfg.cfg_injectorMode = model[currentIndex]
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Mode info:")
            visible: page.showAdvanced
            text: i18n("Curated uses the built-in core set (Gosper, Glider, R-pentomino, LWSS, Block, Acorn, Diehard).")
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Min alive ratio:")

            QQC2.Slider {
                id: minAliveSlider
                Layout.fillWidth: true
                from: 0.05
                to: 0.70
                value: cfg.cfg_minAliveRatio
                onMoved: cfg.cfg_minAliveRatio = value
            }

            QQC2.Label {
                text: Number(minAliveSlider.value).toFixed(2)
                font.family: "monospace"
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Min alive info:")
            text: i18n("Alive ratio target from texture probe. Injection pressure increases when measured ratio is below this value.")
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Rare pattern chance:")
            visible: page.showAdvanced

            QQC2.Slider {
                id: rareSlider
                Layout.fillWidth: true
                from: 0.0
                to: 0.5
                value: cfg.cfg_rarePatternChance
                onMoved: cfg.cfg_rarePatternChance = value
            }

            QQC2.Label {
                text: Number(rareSlider.value).toFixed(2)
                font.family: "monospace"
            }
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Max pattern size:")
            visible: page.showAdvanced
            from: 8
            to: 1024
            value: cfg.cfg_maxPatternSize
            editable: true
            onValueModified: cfg.cfg_maxPatternSize = value
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Large patterns:")
            visible: page.showAdvanced
            text: i18n("Allow stamps above max size")
            checked: cfg.cfg_allowLargePatterns
            onToggled: cfg.cfg_allowLargePatterns = checked
        }

        QQC2.Label {
            Kirigami.FormData.isSection: true
            text: i18n("Enabled categories")
            font.bold: true
            visible: page.showAdvanced
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Categories:")
            spacing: Kirigami.Units.largeSpacing
            visible: page.showAdvanced

            Repeater {
                model: ["gliders", "spaceships", "methuselahs", "oscillators", "guns", "still_lifes"]
                delegate: QQC2.CheckBox {
                    required property string modelData
                    text: modelData
                    checked: page.isCategoryEnabled(modelData)
                    onToggled: page.setCategoryEnabled(modelData, checked)
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 14
            clip: true
            model: page.allPatterns

            delegate: QQC2.ItemDelegate {
                id: delegateRoot
                width: ListView.view.width
                required property var modelData
                text: modelData.name + " (" + modelData.category + ")"
                onClicked: cfg.cfg_previewPatternId = modelData.id

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: delegateRoot.modelData.name + " (" + delegateRoot.modelData.category + ")"
                        elide: Text.ElideRight
                    }

                    QQC2.Button {
                        text: i18n("Preview")
                        onClicked: page.requestPreview(delegateRoot.modelData.id)
                    }
                }
            }
        }

        QQC2.Button {
            Kirigami.FormData.isSection: true
            text: i18n("Reset Pattern Settings to Defaults")
            icon.name: "edit-undo"
            onClicked: cfg.resetPatternsDefaults()
        }
    }
}
