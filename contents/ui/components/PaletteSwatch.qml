import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// A palette chip showing background, dead and alive cell colours.
QQC2.AbstractButton {
    id: swatch

    property color bgColor: "#1A1A1A"
    property color deadColor: "#1A1A1A"
    property color aliveColor: "#50C878"
    property bool selected: false

    implicitWidth: Kirigami.Units.gridUnit * 6.2
    implicitHeight: Kirigami.Units.gridUnit * 3.2
    hoverEnabled: true

    background: Rectangle {
        radius: 6
        color: swatch.hovered || swatch.visualFocus ? Qt.alpha(Kirigami.Theme.textColor, 0.07) : "transparent"
        border.width: swatch.selected ? 2 : 1
        border.color: swatch.selected ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.22)
    }

    contentItem: ColumnLayout {
        spacing: 4

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.4
            radius: 4
            color: swatch.bgColor
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.15)

            Row {
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: [0, 1, 1, 0]
                    delegate: Rectangle {
                        required property int modelData
                        width: Kirigami.Units.gridUnit * 0.55
                        height: width
                        radius: width / 2
                        color: modelData === 1 ? swatch.aliveColor : swatch.deadColor
                    }
                }
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: swatch.text
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.bold: swatch.selected
        }
    }
}
