import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Slider with a live value read-out. `valueEdited` fires only on user input, so
// bindings to the config value are never broken.
RowLayout {
    id: row

    property real from: 0
    property real to: 1
    property real stepSize: 0
    property real value: 0
    property int decimals: 2
    property string unit: ""
    // Optional: function(value) -> string, overrides decimals/unit.
    property var formatter: null
    property bool snap: false
    property color accent: Kirigami.Theme.highlightColor

    signal valueEdited(real newValue)

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    QQC2.Slider {
        id: slider
        Layout.fillWidth: true
        Layout.minimumWidth: Kirigami.Units.gridUnit * 10
        Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        from: row.from
        to: row.to
        stepSize: row.stepSize
        snapMode: row.snap ? QQC2.Slider.SnapAlways : QQC2.Slider.NoSnap
        value: row.value
        palette.highlight: row.accent
        onMoved: row.valueEdited(value)
    }

    QQC2.Label {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 4
        horizontalAlignment: Text.AlignRight
        font.family: "monospace"
        text: row.formatter ? row.formatter(slider.value) : Number(slider.value).toFixed(row.decimals) + row.unit
    }
}
