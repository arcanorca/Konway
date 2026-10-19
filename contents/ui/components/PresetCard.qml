import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Selectable profile card: icon, name and a one-line tagline.
QQC2.AbstractButton {
    id: card

    property string title: ""
    property string tagline: ""
    property string iconName: ""
    property bool selected: false

    implicitWidth: Kirigami.Units.gridUnit * 8
    implicitHeight: Kirigami.Units.gridUnit * 3.6
    hoverEnabled: true

    background: Rectangle {
        radius: 6
        color: card.selected
            ? Qt.alpha(Kirigami.Theme.highlightColor, 0.16)
            : (card.hovered || card.visualFocus ? Qt.alpha(Kirigami.Theme.textColor, 0.07) : "transparent")
        border.width: card.selected ? 2 : 1
        border.color: card.selected ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.22)
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: card.iconName
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                color: card.selected ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: card.title
                font.bold: true
                elide: Text.ElideRight
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: card.tagline
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            color: Kirigami.Theme.disabledTextColor
            verticalAlignment: Text.AlignTop
        }
    }
}
