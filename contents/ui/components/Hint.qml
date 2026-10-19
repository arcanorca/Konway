import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Small explanatory text that sits under a control. Replaces the old
// "Label: description" rows so every setting reads as one unit.
QQC2.Label {
    property bool warning: false

    Layout.fillWidth: true
    Layout.maximumWidth: Kirigami.Units.gridUnit * 30
    wrapMode: Text.WordWrap
    font: Kirigami.Theme.smallFont
    color: warning ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.disabledTextColor
}
