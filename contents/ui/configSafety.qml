import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "components"

Kirigami.ScrollablePage {
    id: page
    property var cfg

    title: i18n("Safety")

    Kirigami.FormLayout {
        width: parent.width

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Visual comfort")
        }

        QQC2.Switch {
            Kirigami.FormData.label: i18n("Safe mode:")
            text: checked ? i18n("On") : i18n("Off")
            checked: cfg.cfg_photosensitiveSafe
            onToggled: cfg.cfg_photosensitiveSafe = checked
        }

        Hint {
            text: i18n("Limits contrast and saturation to reduce eye strain and harsh flicker. Auto-injection also slows down while it is on.")
        }

        SliderRow {
            Kirigami.FormData.label: i18n("Contrast:")
            enabled: cfg.cfg_photosensitiveSafe
            from: 0.40
            to: 1.00
            value: cfg.cfg_safeContrast
            onValueEdited: function (v) { cfg.cfg_safeContrast = v; }
        }

        SliderRow {
            Kirigami.FormData.label: i18n("Saturation:")
            enabled: cfg.cfg_photosensitiveSafe
            from: 0.00
            to: 1.00
            value: cfg.cfg_safeSaturation
            onValueEdited: function (v) { cfg.cfg_safeSaturation = v; }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Motion")
        }

        QQC2.Switch {
            Kirigami.FormData.label: i18n("Speed limiter:")
            enabled: cfg.cfg_photosensitiveSafe
            text: checked ? i18n("On") : i18n("Off")
            checked: cfg.cfg_safeUltraLowTpsEnabled
            onToggled: cfg.cfg_safeUltraLowTpsEnabled = checked
        }

        SliderRow {
            Kirigami.FormData.label: i18n("Speed multiplier:")
            enabled: cfg.cfg_photosensitiveSafe && cfg.cfg_safeUltraLowTpsEnabled
            from: 0.10
            to: 0.99
            stepSize: 0.01
            value: cfg.cfg_safeUltraLowTps
            formatter: function (v) { return Number(v).toFixed(2) + "×"; }
            onValueEdited: function (v) { cfg.cfg_safeUltraLowTps = v; }
        }

    }
}
