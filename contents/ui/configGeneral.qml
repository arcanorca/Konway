import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page
    property var cfg
    readonly property int compactPresetThreshold: Kirigami.Units.gridUnit * 34
    readonly property int narrowPresetThreshold: Kirigami.Units.gridUnit * 24
    readonly property int resetButtonWidth: Kirigami.Units.gridUnit * 11

    title: i18n("General")

    readonly property var presetButtons: [
        { "id": "Quiet", "label": i18n("Quiet") },
        { "id": "Balanced", "label": i18n("Balanced") },
        { "id": "Lively", "label": i18n("Lively") },
        { "id": "Showcase", "label": i18n("Showcase") }
    ]

    readonly property var clockSizeOptions: [
        { "label": i18n("Pocket"), "scale": 0.35 },
        { "label": i18n("Wristwatch"), "scale": 0.55 },
        { "label": i18n("Desk Clock"), "scale": 0.75 },
        { "label": i18n("Wall Clock"), "scale": 1.00 },
        { "label": i18n("Tower Clock"), "scale": 1.35 },
        { "label": i18n("Monument"), "scale": 1.75 },
        { "label": i18n("Monument+"), "scale": 2.00 }
    ]

    function applyPresetAndReseed(presetId) {
        cfg.applyPracticalPreset(presetId);
        cfg.triggerReseed();
    }

    function nearestClockSizeIndexFor(scaleValue) {
        let nearest = 0;
        let bestDistance = 999.0;
        const current = Number(scaleValue);
        for (let i = 0; i < clockSizeOptions.length; ++i) {
            const d = Math.abs(current - Number(clockSizeOptions[i].scale));
            if (d < bestDistance) {
                bestDistance = d;
                nearest = i;
            }
        }
        return nearest;
    }

    Kirigami.FormLayout {
        width: parent.width

        Kirigami.InlineMessage {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18n("One click, full profile shift: presets update Simulation, Patterns, Performance, and Safety together.")
        }

        GridLayout {
            Kirigami.FormData.label: i18n("Preset level:")
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: Kirigami.Units.smallSpacing
            columns: page.width < page.narrowPresetThreshold ? 1
                     : (page.width < page.compactPresetThreshold ? 2 : 4)

            QQC2.ButtonGroup {
                id: presetGroup
            }

            Repeater {
                model: page.presetButtons
                delegate: QQC2.Button {
                    required property var modelData
                    Layout.fillWidth: false
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 8
                    checkable: true
                    text: modelData.label
                    checked: cfg.cfg_preset === modelData.id
                    QQC2.ButtonGroup.group: presetGroup
                    onClicked: page.applyPresetAndReseed(modelData.id)
                }
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Preset summary:")
            text: cfg.presetDescription(cfg.cfg_preset)
            wrapMode: Text.WordWrap
        }

        QQC2.Button {
            Kirigami.FormData.label: i18n("Quick action:")
            text: i18n("Reseed Simulation")
            icon.name: "view-refresh"
            onClicked: cfg.triggerReseed()
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("What it does:")
            text: i18n("Gives the world a fresh start using current settings.")
            wrapMode: Text.WordWrap
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Clock mode:")
            model: ["Off", "Hybrid Local Time"]
            currentIndex: Math.max(0, model.indexOf(cfg.cfg_clockMode))
            onActivated: cfg.cfg_clockMode = model[currentIndex]
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Clock size:")
            Layout.fillWidth: true
            enabled: cfg.cfg_clockMode === "Hybrid Local Time"
            opacity: enabled ? 1.0 : 0.55
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: clockSizeSlider
                Layout.fillWidth: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 14
                Layout.preferredWidth: Kirigami.Units.gridUnit * 18
                Layout.maximumWidth: Kirigami.Units.gridUnit * 24
                from: 0
                to: Math.max(0, page.clockSizeOptions.length - 1)
                stepSize: 1
                snapMode: QQC2.Slider.SnapAlways
                value: page.nearestClockSizeIndexFor(cfg.cfg_clockScale)
                onValueChanged: {
                    const index = Math.max(0, Math.min(page.clockSizeOptions.length - 1, Math.round(value)));
                    const mappedScale = Number(page.clockSizeOptions[index].scale);
                    if (Math.abs(mappedScale - Number(cfg.cfg_clockScale)) > 0.0001) {
                        cfg.cfg_clockScale = mappedScale;
                    }
                }
            }

            QQC2.Label {
                readonly property int clockSizeIndex: Math.max(0, Math.min(page.clockSizeOptions.length - 1, Math.round(clockSizeSlider.value)))
                readonly property real mappedScale: Number(page.clockSizeOptions[clockSizeIndex].scale)
                text: page.clockSizeOptions[clockSizeIndex].label + " (" + mappedScale.toFixed(2) + "x)"
                Layout.minimumWidth: Kirigami.Units.gridUnit * 9
                horizontalAlignment: Text.AlignRight
            }
        }

        QQC2.Label {
            Kirigami.FormData.isSection: true
            text: i18n("Reset options")
            font.bold: true
        }

        QQC2.Button {
            Kirigami.FormData.label: i18n("General tab:")
            text: i18n("Reset General Tab")
            icon.name: "edit-undo"
            Layout.preferredWidth: page.resetButtonWidth
            Layout.minimumWidth: page.resetButtonWidth
            Layout.maximumWidth: page.resetButtonWidth
            onClicked: cfg.resetGeneralDefaults()
        }

        QQC2.Button {
            Kirigami.FormData.label: i18n("All tabs (danger):")
            text: i18n("Reset All Tabs")
            icon.name: "dialog-warning"
            palette.buttonText: Kirigami.Theme.negativeTextColor
            font.bold: true
            Layout.preferredWidth: page.resetButtonWidth
            Layout.minimumWidth: page.resetButtonWidth
            Layout.maximumWidth: page.resetButtonWidth
            onClicked: cfg.resetAllDefaults()
        }
    }
}
