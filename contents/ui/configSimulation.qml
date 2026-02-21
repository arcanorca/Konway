import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page
    property var cfg
    property bool showAdvanced: false
    readonly property real extinctionCoverageThreshold: 0.35
    readonly property int resetButtonWidth: Kirigami.Units.gridUnit * 11

    function startupCoverageFromIntensity(value) {
        const v = Math.max(0.05, Math.min(1.0, Number(value)));
        if (!Number.isFinite(v)) {
            return 0.05;
        }
        if (v <= 0.5) {
            return Math.max(0.005, 0.10 * v);
        }
        const t = (v - 0.5) / 0.5;
        const boosted = 0.05 + (1.0 - 0.05) * Math.pow(t, 2.25);
        return Math.max(0.005, Math.min(1.0, boosted));
    }

    function startupCoveragePercent(value) {
        return Math.round(startupCoverageFromIntensity(value) * 100);
    }

    function startupExtinctionRisk(value) {
        return startupCoverageFromIntensity(value) >= extinctionCoverageThreshold;
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
                property bool extinctionRisk: page.startupExtinctionRisk(value)
                Layout.fillWidth: true
                from: 0.05
                to: 1.00
                stepSize: 0.05
                value: cfg.cfg_initialDensity
                palette.highlight: extinctionRisk ? "#cf4a4a" : "#50C878"

                onValueChanged: {
                    if (Math.abs(cfg.cfg_initialDensity - value) > 0.0001) {
                        cfg.cfg_initialDensity = value;
                    }
                }
            }

            QQC2.Label {
                text: page.startupCoveragePercent(startupIntensitySlider.value) + "%"
                font.family: "monospace"
                color: startupIntensitySlider.extinctionRisk ? "#e17979" : Kirigami.Theme.textColor
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Coverage info:")
            text: i18n("Startup and reseed use this alive-cell coverage ratio. 100% fills the whole simulation grid.")
            wrapMode: Text.WordWrap
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Warning:")
            visible: startupIntensitySlider.extinctionRisk
            color: Kirigami.Theme.negativeTextColor
            text: i18n("High coverage is in overpopulation zone and may cause early mass extinction.")
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
            Kirigami.FormData.label: i18n("Simulation tab:")
            text: i18n("Reset Simulation Tab")
            icon.name: "edit-undo"
            Layout.preferredWidth: page.resetButtonWidth
            Layout.minimumWidth: page.resetButtonWidth
            Layout.maximumWidth: page.resetButtonWidth
            onClicked: cfg.resetSimulationDefaults()
        }
    }
}
