import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "components"

Kirigami.ScrollablePage {
    id: page
    property var cfg

    title: i18n("Performance")

    Kirigami.FormLayout {
        width: parent.width

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Simulation detail")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Downscale:")
            QQC2.SpinBox {
                from: 1
                to: 12
                value: cfg.cfg_simDownscale
                editable: true
                onValueModified: cfg.cfg_simDownscale = value
            }
            QQC2.Label {
                text: "×"
                color: Kirigami.Theme.disabledTextColor
            }
        }

        Hint {
            text: i18n("1 keeps full detail, 2 is usually plenty, higher values simulate a coarser grid and use less power.")
        }


        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Timing")
        }

        QQC2.Switch {
            Kirigami.FormData.label: i18n("Sync with speed:")
            text: checked ? i18n("On") : i18n("Off")
            checked: cfg.cfg_syncFpsWithTps
            onToggled: cfg.cfg_syncFpsWithTps = checked
        }


        QQC2.SpinBox {
            visible: cfg.showAdvanced
            Kirigami.FormData.label: i18n("Steps per frame:")
            from: 1
            to: 8
            value: cfg.cfg_stepsPerFrame
            editable: true
            onValueModified: cfg.cfg_stepsPerFrame = value
        }

        QQC2.SpinBox {
            visible: cfg.showAdvanced && !cfg.cfg_syncFpsWithTps
            Kirigami.FormData.label: i18n("Driver rate cap (Hz):")
            from: 10
            to: 240
            value: cfg.cfg_maxFps
            editable: true
            onValueModified: cfg.cfg_maxFps = value
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Power")
        }

        QQC2.Switch {
            Kirigami.FormData.label: i18n("Pause when inactive:")
            text: checked ? i18n("On") : i18n("Off")
            checked: cfg.cfg_pauseWhenHidden
            onToggled: cfg.cfg_pauseWhenHidden = checked
        }

        Hint {
            text: i18n("Freezes the simulation while Plasma is inactive, for example when the session is not focused, and resumes afterwards.")
        }
    }
}
