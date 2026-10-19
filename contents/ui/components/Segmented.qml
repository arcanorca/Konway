import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Single-choice button strip. Selection is a pure function of `current`, so it
// stays correct when the value is changed from elsewhere (presets, reset).
RowLayout {
    id: seg

    // [{ "id": "a", "label": "A", "icon": "icon-name" (optional) }]
    property var options: []
    property string current: ""

    signal picked(string id)

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    Repeater {
        model: seg.options
        delegate: QQC2.Button {
            required property var modelData
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 9
            text: modelData.label
            icon.name: modelData.icon ? modelData.icon : ""
            highlighted: seg.current === modelData.id
            onClicked: seg.picked(modelData.id)
        }
    }
}
