import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "components"
import "lib/clockFormat.js" as ClockFormat

Kirigami.ScrollablePage {
    id: page
    property var cfg

    title: i18n("General")

    readonly property var clockSizeOptions: [
        { "label": i18n("Pocket"), "scale": 0.35 },
        { "label": i18n("Wristwatch"), "scale": 0.55 },
        { "label": i18n("Desk Clock"), "scale": 0.75 },
        { "label": i18n("Wall Clock"), "scale": 1.00 },
        { "label": i18n("Tower Clock"), "scale": 1.35 },
        { "label": i18n("Monument"), "scale": 1.75 },
        { "label": i18n("Monument+"), "scale": 2.00 }
    ]

    readonly property bool clockOn: cfg.cfg_clockMode === "Hybrid Local Time"
    readonly property bool twelveHour: cfg.cfg_clockHourFormat === "12h"
    readonly property string clockPreview: {
        // 21:05 shows the difference between both formats at a glance.
        const f = ClockFormat.formatClock(new Date(2026, 0, 1, 21, 5), {
            hour12: twelveHour,
            showAmPm: cfg.cfg_clockShowAmPm,
            leadingZero: cfg.cfg_clockLeadingZero
        });
        return f.suffix.length > 0 ? f.text + " " + f.suffix : f.text;
    }

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

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Profile")
        }

        GridLayout {
            Layout.fillWidth: true
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: Kirigami.Units.smallSpacing
            uniformCellWidths: true
            columns: page.width < Kirigami.Units.gridUnit * 26 ? 2
                     : (page.width < Kirigami.Units.gridUnit * 40 ? 3 : 5)

            Repeater {
                model: cfg.practicalPresetOrder
                delegate: PresetCard {
                    required property string modelData
                    Layout.fillWidth: true
                    title: modelData
                    tagline: cfg.presetTagline(modelData)
                    iconName: cfg.presetIcon(modelData)
                    selected: cfg.cfg_preset === modelData
                    onClicked: page.applyPresetAndReseed(modelData)
                }
            }
        }

        Hint {
            text: cfg.presetDescription(cfg.cfg_preset)
        }


        QQC2.Button {
            text: i18n("Reseed Simulation")
            icon.name: "view-refresh"
            onClicked: cfg.triggerReseed()
        }


        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Clock")
        }

        QQC2.Switch {
            Kirigami.FormData.label: i18n("Show clock:")
            text: checked ? i18n("On") : i18n("Off")
            checked: page.clockOn
            onToggled: cfg.cfg_clockMode = checked ? "Hybrid Local Time" : "Off"
        }


        RowLayout {
            Kirigami.FormData.label: i18n("Time format:")
            enabled: page.clockOn
            spacing: Kirigami.Units.largeSpacing

            Segmented {
                Layout.fillWidth: false
                options: [
                    { "id": "24h", "label": i18n("24-hour") },
                    { "id": "12h", "label": i18n("12-hour") }
                ]
                current: cfg.cfg_clockHourFormat
                onPicked: function (id) { cfg.cfg_clockHourFormat = id; }
            }

            QQC2.CheckBox {
                enabled: page.twelveHour
                text: i18n("AM/PM")
                checked: cfg.cfg_clockShowAmPm
                onToggled: cfg.cfg_clockShowAmPm = checked
            }

            QQC2.CheckBox {
                enabled: page.twelveHour
                text: i18n("Leading zero")
                checked: cfg.cfg_clockLeadingZero
                onToggled: cfg.cfg_clockLeadingZero = checked
            }

            QQC2.Label {
                text: page.clockPreview
                font.family: "monospace"
                font.bold: true
            }
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("When paused:")
            enabled: page.clockOn
            text: i18n("Keep the clock visible and ticking")
            checked: cfg.cfg_clockWhilePaused
            onToggled: cfg.cfg_clockWhilePaused = checked
        }

        SliderRow {
            id: clockSizeRow
            Kirigami.FormData.label: i18n("Clock size:")
            enabled: page.clockOn
            from: 0
            to: Math.max(0, page.clockSizeOptions.length - 1)
            stepSize: 1
            snap: true
            value: page.nearestClockSizeIndexFor(cfg.cfg_clockScale)
            formatter: function (v) {
                const i = Math.max(0, Math.min(page.clockSizeOptions.length - 1, Math.round(v)));
                return page.clockSizeOptions[i].label;
            }
            onValueEdited: function (v) {
                const i = Math.max(0, Math.min(page.clockSizeOptions.length - 1, Math.round(v)));
                cfg.cfg_clockScale = Number(page.clockSizeOptions[i].scale);
            }
        }
    }
}
