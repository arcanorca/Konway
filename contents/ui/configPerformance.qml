import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page
    property var cfg
    property bool showAdvanced: false

    title: i18n("Performance")

    Kirigami.FormLayout {
        width: parent.width

        Kirigami.InlineMessage {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18n("For most users, downscale 1 or 2 is enough. Driver timing can stay synced with TPS.")
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Simulation downscale:")
            from: 1
            to: 12
            value: cfg.cfg_simDownscale
            editable: true
            onValueModified: cfg.cfg_simDownscale = value
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Downscale info:")
            text: i18n("1 keeps maximum simulation detail. 2 is usually enough. Higher values reduce detail and lower load.")
            wrapMode: Text.WordWrap
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Safety guard:")
            text: i18n("If the computed grid becomes too dense, Konway automatically increases downscale to prevent freezes.")
            wrapMode: Text.WordWrap
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Driver timing:")
            text: i18n("Sync with TPS")
            checked: cfg.cfg_syncFpsWithTps
            onToggled: cfg.cfg_syncFpsWithTps = checked
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Sync info:")
            text: i18n("Enabled: driver rate follows TPS automatically. Disabled: use manual driver Hz cap.")
            wrapMode: Text.WordWrap
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Advanced:")
            text: i18n("Show advanced performance controls")
            checked: page.showAdvanced
            onToggled: page.showAdvanced = checked
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Steps per frame (advanced):")
            visible: page.showAdvanced
            from: 1
            to: 8
            value: cfg.cfg_stepsPerFrame
            editable: true
            onValueModified: cfg.cfg_stepsPerFrame = value
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Manual driver Hz cap (advanced):")
            visible: page.showAdvanced && !cfg.cfg_syncFpsWithTps
            from: 10
            to: 240
            value: cfg.cfg_maxFps
            editable: true
            onValueModified: cfg.cfg_maxFps = value
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Power save:")
            text: i18n("Pause when Plasma is inactive")
            checked: cfg.cfg_pauseWhenHidden
            onToggled: cfg.cfg_pauseWhenHidden = checked
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Pause behavior:")
            text: i18n("Pauses simulation when Plasma is inactive (for example when session is not focused).")
            wrapMode: Text.WordWrap
        }

        QQC2.Button {
            Kirigami.FormData.isSection: true
            text: i18n("Reset Performance to Defaults")
            icon.name: "edit-undo"
            onClicked: cfg.resetPerformanceDefaults()
        }
    }
}
