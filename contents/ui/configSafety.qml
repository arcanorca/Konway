import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page
    property var cfg
    readonly property real sliderWidth: Kirigami.Units.gridUnit * 11

    title: i18n("Safety")

    Kirigami.FormLayout {
        width: parent.width

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Safe mode:")
            text: i18n("Enable visual safety limits")
            checked: cfg.cfg_photosensitiveSafe
            onToggled: cfg.cfg_photosensitiveSafe = checked
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Contrast:")

            QQC2.Slider {
                id: safeContrastSlider
                Layout.preferredWidth: page.sliderWidth
                Layout.maximumWidth: page.sliderWidth
                from: 0.40
                to: 1.00
                value: cfg.cfg_safeContrast
                enabled: cfg.cfg_photosensitiveSafe
                onMoved: cfg.cfg_safeContrast = value
            }

            QQC2.Label {
                text: Number(safeContrastSlider.value).toFixed(2)
                font.family: "monospace"
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Saturation:")

            QQC2.Slider {
                id: safeSaturationSlider
                Layout.preferredWidth: page.sliderWidth
                Layout.maximumWidth: page.sliderWidth
                from: 0.00
                to: 1.00
                value: cfg.cfg_safeSaturation
                enabled: cfg.cfg_photosensitiveSafe
                onMoved: cfg.cfg_safeSaturation = value
            }

            QQC2.Label {
                text: Number(safeSaturationSlider.value).toFixed(2)
                font.family: "monospace"
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Optional speed limiter:")

            QQC2.CheckBox {
                text: i18n("Enable TPS multiplier limit")
                checked: cfg.cfg_safeUltraLowTpsEnabled
                enabled: cfg.cfg_photosensitiveSafe
                onToggled: cfg.cfg_safeUltraLowTpsEnabled = checked
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("TPS multiplier:")

            QQC2.Slider {
                id: ultraLowTpsSlider
                Layout.preferredWidth: page.sliderWidth
                Layout.maximumWidth: page.sliderWidth
                from: 0.10
                to: 0.99
                stepSize: 0.01
                value: cfg.cfg_safeUltraLowTps
                enabled: cfg.cfg_photosensitiveSafe && cfg.cfg_safeUltraLowTpsEnabled
                onMoved: cfg.cfg_safeUltraLowTps = value
            }

            QQC2.Label {
                text: Number(ultraLowTpsSlider.value).toFixed(2) + "x"
                font.family: "monospace"
            }
        }

        Kirigami.InlineMessage {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            type: Kirigami.MessageType.Warning
            text: i18n("Safe mode limits contrast and saturation. Optional TPS limiter reduces motion rate.")
        }

        QQC2.Button {
            Kirigami.FormData.isSection: true
            text: i18n("Reset Safety to Defaults")
            icon.name: "edit-undo"
            onClicked: cfg.resetSafetyDefaults()
        }
    }
}
