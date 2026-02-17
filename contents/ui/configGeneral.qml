import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page
    property var cfg

    title: i18n("General")

    readonly property var presetButtons: [
        { "id": "Quiet", "label": i18n("Quiet") },
        { "id": "Balanced", "label": i18n("Balanced") },
        { "id": "Lively", "label": i18n("Lively") },
        { "id": "Showcase", "label": i18n("Showcase") }
    ]

    readonly property var clockSizeOptions: [
        { "label": i18n("Wristwatch"), "scale": 0.75 },
        { "label": i18n("Desk Clock"), "scale": 1.00 },
        { "label": i18n("Wall Clock"), "scale": 1.25 },
        { "label": i18n("Tower Clock"), "scale": 1.50 }
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

        RowLayout {
            Kirigami.FormData.label: i18n("Preset level:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.ButtonGroup {
                id: presetGroup
            }

            Repeater {
                model: page.presetButtons
                delegate: QQC2.Button {
                    required property var modelData
                    Layout.fillWidth: true
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
            enabled: cfg.cfg_clockMode === "Hybrid Local Time"
            opacity: enabled ? 1.0 : 0.55

            QQC2.Slider {
                id: clockSizeSlider
                Layout.preferredWidth: Kirigami.Units.gridUnit * 11
                Layout.maximumWidth: Kirigami.Units.gridUnit * 11
                from: 0.75
                to: 1.50
                stepSize: 0.25
                value: cfg.cfg_clockScale
                onMoved: cfg.cfg_clockScale = Math.round(value * 4.0) / 4.0
            }

            QQC2.Label {
                readonly property int clockSizeIndex: page.nearestClockSizeIndexFor(clockSizeSlider.value)
                text: page.clockSizeOptions[clockSizeIndex].label
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Clock info:")
            text: cfg.cfg_clockMode === "Hybrid Local Time"
                  ? i18n("Clock stays centered in a protected zone while cells continue evolving around it.")
                  : i18n("Enable Clock mode to adjust clock size.")
            wrapMode: Text.WordWrap
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Diagnostics:")
            text: i18n("Debug logging toggle is in Simulation > Advanced.")
            wrapMode: Text.WordWrap
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
            onClicked: cfg.resetGeneralDefaults()
        }

        QQC2.Button {
            Kirigami.FormData.label: i18n("All tabs:")
            text: i18n("Reset All Tabs")
            icon.name: "edit-reset"
            onClicked: cfg.resetAllDefaults()
        }
    }
}
