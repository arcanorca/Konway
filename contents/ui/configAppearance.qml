import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls
import "components"
import "lib/mainConstants.js" as MainConstants

Kirigami.ScrollablePage {
    id: page
    property var cfg

    title: i18n("Appearance")

    readonly property var paletteOrder: [
        "Calm Dark", "Paper Light", "Emerald", "Amber", "Monochrome", "Catppuccin",
        "Dracula", "Tokyo Night", "Nord", "Gruvbox", "Everforest", "Rose Pine",
        "Amiga", "Ayu Dark", "Ayu Mirage", "Braun", "Casio Digital", "Classic Macintosh", "Commodore 64", "Cyberpunk", "Grayscale", "Hacker Green", "Handheld", "Kanagawa", "macOS", "Material Ocean", "Monokai", "Nintendo DS", "Night Owl", "Nixie", "Nothing", "One Dark", "Oscilloscope", "Phosphor Blue", "PlayStation 3", "Solarized Dark", "Synthwave 84", "Terminal", "ThinkPad", "UNIX Workstation", "VFD Hi-Fi", "Nintendo Wii", "Windows XP", "Zenburn",
        "Midnight", "Sakura", "Sand Dune", "Glacier"
    ]
    readonly property var palettes: MainConstants.paletteDefaults
    readonly property var shapeOptions: [
        { "id": "Square", "label": i18n("Square") },
        { "id": "Go Board", "label": i18n("Go Board") },
        { "id": "Circle", "label": i18n("Circle") }
    ]

    // Largest divisor of the palette count that fits, so every row is full.
    function paletteColumns(w) {
        const fit = Math.max(1, Math.floor(w / (Kirigami.Units.gridUnit * 6.2)));
        const options = [12, 8, 6, 4, 3, 2, 1];
        for (let i = 0; i < options.length; ++i) {
            if (options[i] <= fit && paletteOrder.length % options[i] === 0) {
                return options[i];
            }
        }
        return 1;
    }

    function sameColor(a, b) {
        return String(Qt.color(a)).toLowerCase() === String(Qt.color(b)).toLowerCase();
    }

    function paletteMatches(name) {
        const p = palettes[name];
        return !!p
            && sameColor(cfg.cfg_aliveColor, p.alive)
            && sameColor(cfg.cfg_deadColor, p.dead)
            && sameColor(cfg.cfg_backgroundColor, p.bg);
    }

    readonly property bool usingCustomColors: {
        for (let i = 0; i < paletteOrder.length; ++i) {
            if (paletteMatches(paletteOrder[i])) {
                return false;
            }
        }
        return true;
    }

    function applyPalette(name) {
        const p = palettes[name];
        if (!p) {
            return;
        }
        cfg.cfg_palette = name;
        cfg.cfg_backgroundColor = p.bg;
        cfg.cfg_deadColor = p.dead;
        cfg.cfg_aliveColor = p.alive;
    }

    function setTransitionTicks(rawValue) {
        const rounded = Math.max(1, Math.min(8, Math.round(Number(rawValue))));
        if (cfg.cfg_dyingFadeTicks !== rounded) {
            cfg.cfg_dyingFadeTicks = rounded;
        }
        if (cfg.wallpaperConfiguration) {
            cfg.wallpaperConfiguration["dyingFadeTicks"] = rounded;
        }
    }

    Kirigami.FormLayout {
        width: parent.width

        LivePreview {
            bgColor: cfg.cfg_backgroundColor
            deadColor: cfg.cfg_deadColor
            aliveColor: cfg.cfg_aliveColor
            shape: cfg.cfg_cellShape
            fade: cfg.cfg_dyingFadeEnabled || (cfg.cfg_chillMode && cfg.cfg_chillSoftFade)
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Palette")
        }

        Flickable {
            id: palFlick
            Layout.fillWidth: true
            implicitHeight: Kirigami.Units.gridUnit * 15
            Layout.preferredHeight: Kirigami.Units.gridUnit * 15
            Layout.maximumHeight: Kirigami.Units.gridUnit * 15
            contentWidth: width
            contentHeight: paletteGrid.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

        GridLayout {
            id: paletteGrid
            width: palFlick.width - Kirigami.Units.gridUnit
            columns: page.paletteColumns(palFlick.width)
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            Repeater {
                model: page.paletteOrder
                delegate: PaletteSwatch {
                    required property string modelData
                    Layout.fillWidth: true
                    text: modelData
                    bgColor: page.palettes[modelData].bg
                    deadColor: page.palettes[modelData].dead
                    aliveColor: page.palettes[modelData].alive
                    selected: page.paletteMatches(modelData)
                    onClicked: page.applyPalette(modelData)
                }
            }
        }
        }


        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Cells")
        }

        Segmented {
            Kirigami.FormData.label: i18n("Cell style:")
            options: page.shapeOptions
            current: cfg.cfg_cellShape
            onPicked: function (id) { cfg.cfg_cellShape = id; }
        }


        QQC2.Switch {
            Kirigami.FormData.label: i18n("Fading trails:")
            text: checked ? i18n("On") : i18n("Off")
            checked: cfg.cfg_dyingFadeEnabled
            onToggled: {
                cfg.cfg_dyingFadeEnabled = checked;
                if (cfg.wallpaperConfiguration) {
                    cfg.wallpaperConfiguration["dyingFadeEnabled"] = checked;
                }
            }
        }

        SliderRow {
            Kirigami.FormData.label: i18n("Trail length:")
            enabled: cfg.cfg_dyingFadeEnabled
            from: 1
            to: 8
            stepSize: 1
            snap: true
            value: Math.max(1, Math.min(8, cfg.cfg_dyingFadeTicks))
            formatter: function (v) { return i18np("%1 tick", "%1 ticks", Math.round(v)); }
            onValueEdited: function (v) { page.setTransitionTicks(v); }
        }


        RowLayout {
            Kirigami.FormData.label: i18n("Colors:")
            spacing: Kirigami.Units.largeSpacing

            KQuickControls.ColorButton {
                color: cfg.cfg_aliveColor
                onColorChanged: cfg.cfg_aliveColor = color
                dialogTitle: i18n("Pick Alive Cell Color")
            }

            KQuickControls.ColorButton {
                color: cfg.cfg_deadColor
                onColorChanged: cfg.cfg_deadColor = color
                dialogTitle: i18n("Pick Dead Cell Color")
            }

            KQuickControls.ColorButton {
                color: cfg.cfg_backgroundColor
                onColorChanged: cfg.cfg_backgroundColor = color
                dialogTitle: i18n("Pick Background Color")
            }
        }
    }
}
