import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "components"

Kirigami.ScrollablePage {
    id: page
    property var cfg

    title: i18n("Zen")

    readonly property bool chillOn: cfg.cfg_chillMode

    function hourText(h) {
        return String(h).padStart(2, "0") + ":00";
    }

    function breathingName(v) {
        if (v < 0.02) {
            return i18n("Off");
        }
        if (v < 0.20) {
            return i18n("Subtle");
        }
        if (v < 0.40) {
            return i18n("Gentle");
        }
        return i18n("Deep");
    }

    Kirigami.FormLayout {
        width: parent.width

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Zen mode")
        }

        QQC2.Switch {
            Kirigami.FormData.label: i18n("Relax:")
            text: checked ? i18n("On") : i18n("Off")
            checked: cfg.cfg_chillMode
            onToggled: cfg.cfg_chillMode = checked
        }

        Hint {
            text: i18n("Softens the whole wallpaper: the tempo drifts slowly, trails linger, new life arrives gently, and it can dim itself in the evening. Everything below applies only while Zen mode is on.")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Motion")
        }

        SliderRow {
            Kirigami.FormData.label: i18n("Breathing tempo:")
            enabled: page.chillOn
            from: 0.0
            to: 0.6
            stepSize: 0.05
            value: cfg.cfg_chillBreathing
            formatter: function (v) { return page.breathingName(v); }
            onValueEdited: function (v) { cfg.cfg_chillBreathing = v; }
        }


        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Softness:")
            enabled: page.chillOn
            text: i18n("Long, soft fading trails")
            checked: cfg.cfg_chillSoftFade
            onToggled: cfg.cfg_chillSoftFade = checked
        }

        QQC2.CheckBox {
            enabled: page.chillOn
            text: i18n("Gentle injections")
            checked: cfg.cfg_chillGentleInjection
            onToggled: cfg.cfg_chillGentleInjection = checked
        }


        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Evening dim")
        }

        QQC2.Switch {
            Kirigami.FormData.label: i18n("Dim at night:")
            enabled: page.chillOn
            text: checked ? i18n("On") : i18n("Off")
            checked: cfg.cfg_chillDimEnabled
            onToggled: cfg.cfg_chillDimEnabled = checked
        }

        SliderRow {
            Kirigami.FormData.label: i18n("Dim amount:")
            enabled: page.chillOn && cfg.cfg_chillDimEnabled
            from: 0.05
            to: 0.80
            stepSize: 0.05
            value: cfg.cfg_chillDimLevel
            formatter: function (v) { return Math.round(v * 100) + "%"; }
            onValueEdited: function (v) { cfg.cfg_chillDimLevel = v; }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Schedule:")
            enabled: page.chillOn && cfg.cfg_chillDimEnabled
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: i18n("From")
            }

            QQC2.SpinBox {
                from: 0
                to: 23
                value: cfg.cfg_chillDimStart
                textFromValue: function (value) { return page.hourText(value); }
                valueFromText: function (text) { return Math.max(0, Math.min(23, parseInt(text) || 0)); }
                editable: true
                onValueModified: cfg.cfg_chillDimStart = value
            }

            QQC2.Label {
                text: i18n("until")
            }

            QQC2.SpinBox {
                from: 0
                to: 23
                value: cfg.cfg_chillDimEnd
                textFromValue: function (value) { return page.hourText(value); }
                valueFromText: function (text) { return Math.max(0, Math.min(23, parseInt(text) || 0)); }
                editable: true
                onValueModified: cfg.cfg_chillDimEnd = value
            }
        }

    }
}
