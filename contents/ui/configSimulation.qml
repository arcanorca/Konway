import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "components"

Kirigami.ScrollablePage {
    id: page
    property var cfg

    readonly property real extinctionCoverageThreshold: 0.35
    readonly property var rulePresets: [
        { "name": i18n("Conway's Life"), "rule": "B3/S23" },
        { "name": i18n("HighLife"), "rule": "B36/S23" },
        { "name": i18n("Day & Night"), "rule": "B3678/S34678" },
        { "name": i18n("Seeds"), "rule": "B2/S" },
        { "name": i18n("Life without Death"), "rule": "B3/S012345678" }
    ]

    readonly property var ruleModel: rulePresets.map(function (r) { return r.name + "  (" + r.rule + ")"; }).concat([i18n("Custom")])

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

    function rulePresetIndex(rule) {
        for (let i = 0; i < rulePresets.length; ++i) {
            if (rulePresets[i].rule === rule) {
                return i;
            }
        }
        return rulePresets.length;
    }

    title: i18n("Simulation")

    Kirigami.FormLayout {
        width: parent.width

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("World")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Cell size:")
            QQC2.SpinBox {
                from: 2
                to: 32
                value: cfg.cfg_cellSize
                editable: true
                onValueModified: cfg.cfg_cellSize = value
            }
            QQC2.Label {
                text: i18n("px")
                color: Kirigami.Theme.disabledTextColor
            }
        }


        RowLayout {
            Kirigami.FormData.label: i18n("Speed:")
            QQC2.SpinBox {
                from: 1
                to: 20
                value: cfg.cfg_tps
                editable: true
                onValueModified: cfg.cfg_tps = value
            }
            QQC2.Label {
                text: i18n("generations / second")
                color: Kirigami.Theme.disabledTextColor
            }
        }

        Hint {
            text: i18n("1–3 is relaxed, 6–10 is lively. Very high values are rarely useful on a wallpaper.")
        }

        QQC2.Switch {
            Kirigami.FormData.label: i18n("Wrap edges:")
            text: checked ? i18n("On (torus)") : i18n("Off")
            checked: cfg.cfg_wrapEdges
            onToggled: cfg.cfg_wrapEdges = checked
        }

        Hint {
            text: cfg.cfg_wrapEdges
                  ? i18n("Left and right, top and bottom are connected, so gliders keep travelling.")
                  : i18n("Cells outside the screen count as dead, so travelling patterns die at the edges.")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Startup")
        }

        SliderRow {
            id: startupIntensity
            Kirigami.FormData.label: i18n("Seed intensity:")
            from: 0.05
            to: 1.00
            stepSize: 0.05
            value: cfg.cfg_initialDensity
            accent: page.startupExtinctionRisk(value) ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.positiveTextColor
            formatter: function (v) { return page.startupCoveragePercent(v) + "%"; }
            onValueEdited: function (v) { cfg.cfg_initialDensity = v; }
        }


        Hint {
            visible: page.startupExtinctionRisk(cfg.cfg_initialDensity)
            warning: true
            text: i18n("This is in the overpopulation zone and may cause early mass extinction.")
        }

        Kirigami.Separator {
            visible: cfg.showAdvanced
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Rules")
        }

        QQC2.ComboBox {
            visible: cfg.showAdvanced
            Kirigami.FormData.label: i18n("Rule set:")
            model: page.ruleModel
            currentIndex: page.rulePresetIndex(cfg.cfg_ruleString)
            onActivated: function (index) {
                if (index < page.rulePresets.length) {
                    cfg.cfg_ruleString = page.rulePresets[index].rule;
                }
            }
        }

        QQC2.TextField {
            visible: cfg.showAdvanced
            Kirigami.FormData.label: i18n("Rule (B/S):")
            text: cfg.cfg_ruleString
            placeholderText: "B3/S23"
            onEditingFinished: cfg.cfg_ruleString = text.length > 0 ? text : "B3/S23"
        }

        Hint {
            visible: cfg.showAdvanced
            text: i18n("B3/S23 means: a cell is born with exactly 3 neighbours and survives with 2 or 3. Built-in patterns assume this rule.")
        }

        Kirigami.Separator {
            visible: cfg.showAdvanced
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Diagnostics")
        }

        QQC2.CheckBox {
            visible: cfg.showAdvanced
            Kirigami.FormData.label: i18n("Debug:")
            text: i18n("Show debug overlay and log activity decisions")
            checked: cfg.cfg_debugLogging
            onToggled: cfg.cfg_debugLogging = checked
        }
    }
}
