import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls

Kirigami.ScrollablePage {
    id: page
    property var cfg

    title: i18n("Appearance")

    function applyPalette(name) {
        if (name === "Calm Dark") {
            cfg.cfg_backgroundColor = "#1A1A1A";
            cfg.cfg_deadColor = "#1A1A1A";
            cfg.cfg_aliveColor = "#50C878";
        } else if (name === "Paper Light") {
            cfg.cfg_backgroundColor = "#F3EFE6";
            cfg.cfg_deadColor = "#DDD5C6";
            cfg.cfg_aliveColor = "#537F67";
        } else if (name === "Emerald") {
            cfg.cfg_backgroundColor = "#0D1714";
            cfg.cfg_deadColor = "#12221D";
            cfg.cfg_aliveColor = "#4FBF8A";
        } else if (name === "Amber") {
            cfg.cfg_backgroundColor = "#18120A";
            cfg.cfg_deadColor = "#2A1D10";
            cfg.cfg_aliveColor = "#CFA15C";
        } else if (name === "Monochrome") {
            cfg.cfg_backgroundColor = "#101010";
            cfg.cfg_deadColor = "#1D1D1D";
            cfg.cfg_aliveColor = "#AFAFAF";
        } else if (name === "Catppuccin") {
            cfg.cfg_backgroundColor = "#1E1E2E";
            cfg.cfg_deadColor = "#313244";
            cfg.cfg_aliveColor = "#A6E3A1";
        } else if (name === "Dracula") {
            cfg.cfg_backgroundColor = "#282A36";
            cfg.cfg_deadColor = "#44475A";
            cfg.cfg_aliveColor = "#50FA7B";
        } else if (name === "Tokyo Night") {
            cfg.cfg_backgroundColor = "#1A1B26";
            cfg.cfg_deadColor = "#292E42";
            cfg.cfg_aliveColor = "#73DACA";
        } else if (name === "Nord") {
            cfg.cfg_backgroundColor = "#2E3440";
            cfg.cfg_deadColor = "#3B4252";
            cfg.cfg_aliveColor = "#A3BE8C";
        } else if (name === "Gruvbox") {
            cfg.cfg_backgroundColor = "#282828";
            cfg.cfg_deadColor = "#3C3836";
            cfg.cfg_aliveColor = "#FABD2F";
        } else if (name === "Everforest") {
            cfg.cfg_backgroundColor = "#2D353B";
            cfg.cfg_deadColor = "#3D484D";
            cfg.cfg_aliveColor = "#A7C080";
        } else if (name === "Rose Pine") {
            cfg.cfg_backgroundColor = "#1F1C21";
            cfg.cfg_deadColor = "#1F1C21";
            cfg.cfg_aliveColor = "#A890B6";
        }
    }

    Kirigami.FormLayout {
        width: parent.width

        Kirigami.InlineMessage {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18n("Configure palette, cell shape, and dying-cell transition.")
        }

        QQC2.ComboBox {
            id: paletteCombo
            Kirigami.FormData.label: i18n("Palette:")
            model: [
                "Calm Dark",
                "Paper Light",
                "Emerald",
                "Amber",
                "Monochrome",
                "Catppuccin",
                "Dracula",
                "Tokyo Night",
                "Nord",
                "Gruvbox",
                "Everforest",
                "Rose Pine"
            ]
            currentIndex: Math.max(0, model.indexOf(cfg.cfg_palette))
            onActivated: {
                cfg.cfg_palette = model[currentIndex];
                page.applyPalette(cfg.cfg_palette);
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Cell style:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.ButtonGroup {
                id: shapeGroup
            }

            QQC2.Button {
                Layout.fillWidth: true
                checkable: true
                checked: cfg.cfg_cellShape === "Square"
                text: i18n("Square")
                QQC2.ButtonGroup.group: shapeGroup
                onClicked: cfg.cfg_cellShape = "Square"
            }

            QQC2.Button {
                Layout.fillWidth: true
                checkable: true
                checked: cfg.cfg_cellShape === "Go Board"
                text: i18n("Go Board")
                QQC2.ButtonGroup.group: shapeGroup
                onClicked: cfg.cfg_cellShape = "Go Board"
            }

            QQC2.Button {
                Layout.fillWidth: true
                checkable: true
                checked: cfg.cfg_cellShape === "Circle"
                text: i18n("Circle")
                QQC2.ButtonGroup.group: shapeGroup
                onClicked: cfg.cfg_cellShape = "Circle"
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Shape effect:")
            text: i18n("Go Board uses circular cells with a light grid overlay.")
            wrapMode: Text.WordWrap
        }

        KQuickControls.ColorButton {
            Kirigami.FormData.label: i18n("Alive color:")
            color: cfg.cfg_aliveColor
            onColorChanged: cfg.cfg_aliveColor = color
            dialogTitle: i18n("Pick Alive Cell Color")
        }

        KQuickControls.ColorButton {
            Kirigami.FormData.label: i18n("Dead color:")
            color: cfg.cfg_deadColor
            onColorChanged: cfg.cfg_deadColor = color
            dialogTitle: i18n("Pick Dead Cell Color")
        }

        KQuickControls.ColorButton {
            Kirigami.FormData.label: i18n("Background color:")
            color: cfg.cfg_backgroundColor
            onColorChanged: cfg.cfg_backgroundColor = color
            dialogTitle: i18n("Pick Background Color")
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Transition:")
            text: i18n("Soft fade for dying cells (1 tick)")
            checked: cfg.cfg_dyingFadeEnabled
            onToggled: cfg.cfg_dyingFadeEnabled = checked
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Transition info:")
            text: i18n("When enabled, dying cells are rendered at 50% intensity for one tick.")
            wrapMode: Text.WordWrap
        }

        QQC2.Button {
            Kirigami.FormData.isSection: true
            text: i18n("Reset Appearance to Defaults")
            icon.name: "edit-undo"
            onClicked: cfg.resetAppearanceDefaults()
        }
    }
}
