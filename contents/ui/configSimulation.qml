import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page
    property var cfg
    property bool showAdvanced: false

    readonly property var startupSeedProfiles: [
        { max: 0.20, name: i18n("Firefly"), note: i18n("Tiny sparks, slow organic growth.") },
        { max: 0.40, name: i18n("Breeze"), note: i18n("Light and calm opening density.") },
        { max: 0.60, name: i18n("Garden"), note: i18n("Balanced opening with clear structure.") },
        { max: 0.80, name: i18n("Storm"), note: i18n("Dense opening with fast interactions.") },
        { max: 1.01, name: i18n("Supernova"), note: i18n("Very dense start; dramatic early collisions.") }
    ]

    function startupSeedProfile(value) {
        const v = Number(value);
        for (let i = 0; i < startupSeedProfiles.length; ++i) {
            if (v < startupSeedProfiles[i].max) {
                return startupSeedProfiles[i];
            }
        }
        return startupSeedProfiles[startupSeedProfiles.length - 1];
    }

    title: i18n("Simulation")

    Kirigami.FormLayout {
        width: parent.width

        Kirigami.InlineMessage {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18n("Cell size controls visual scale. Target TPS controls simulation speed.")
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Cell size:")
            from: 2
            to: 32
            value: cfg.cfg_cellSize
            editable: true
            onValueModified: cfg.cfg_cellSize = value
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Target TPS:")
            from: 1
            to: 120
            value: cfg.cfg_tps
            editable: true
            onValueModified: cfg.cfg_tps = value
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("World edges:")
            text: i18n("Wrap around edges (toroidal topology)")
            checked: cfg.cfg_wrapEdges
            onToggled: cfg.cfg_wrapEdges = checked
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Topology info:")
            text: cfg.cfg_wrapEdges
                  ? i18n("ON: Left/right and top/bottom are connected.")
                  : i18n("OFF: Cells outside the screen are treated as dead.")
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Startup seed intensity:")

            QQC2.Slider {
                id: startupIntensitySlider
                Layout.fillWidth: true
                from: 0.05
                to: 1.00
                stepSize: 0.05
                value: cfg.cfg_initialDensity
                onValueChanged: {
                    if (Math.abs(cfg.cfg_initialDensity - value) > 0.0001) {
                        cfg.cfg_initialDensity = value;
                    }
                }
            }

            QQC2.Label {
                text: Math.round(startupIntensitySlider.value * 100) + "%"
                font.family: "monospace"
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Intensity info:")
            text: i18n("Controls how strong startup and reseed begin. Very high values can trigger early mass die-off, which is normal in Life.")
            wrapMode: Text.WordWrap
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Seed style:")
            readonly property var profile: page.startupSeedProfile(startupIntensitySlider.value)
            text: profile.name + "  -  " + profile.note
            wrapMode: Text.WordWrap
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Advanced:")
            text: i18n("Show advanced simulation controls")
            checked: page.showAdvanced
            onToggled: page.showAdvanced = checked
        }

        QQC2.TextField {
            Kirigami.FormData.label: i18n("Rule (B/S):")
            visible: page.showAdvanced
            text: cfg.cfg_ruleString
            placeholderText: "B3/S23"
            onEditingFinished: {
                cfg.cfg_ruleString = text.length > 0 ? text : "B3/S23"
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Rule meaning:")
            visible: page.showAdvanced
            text: i18n("B3/S23: birth with exactly 3 neighbors, survival with 2 or 3 neighbors.")
            wrapMode: Text.WordWrap
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Example rules:")
            visible: page.showAdvanced
            text: i18n("HighLife (B36/S23), Day & Night (B3678/S34678), Seeds (B2/S), Life without Death (B3/S012345678)")
            wrapMode: Text.WordWrap
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Diagnostics:")
            visible: page.showAdvanced
            text: i18n("Enable debug logging")
            checked: cfg.cfg_debugLogging
            onToggled: cfg.cfg_debugLogging = checked
        }

        QQC2.Button {
            Kirigami.FormData.isSection: true
            text: i18n("Reset Simulation to Defaults")
            icon.name: "edit-undo"
            onClicked: cfg.resetSimulationDefaults()
        }
    }
}
