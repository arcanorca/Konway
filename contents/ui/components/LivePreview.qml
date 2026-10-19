import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Miniature wallpaper that reflects the current palette, cell style and fade.
Rectangle {
    id: preview

    property color bgColor: "#1A1A1A"
    property color deadColor: "#1A1A1A"
    property color aliveColor: "#50C878"
    property string shape: "Go Board"
    property bool fade: true

    readonly property int cols: 30
    readonly property int rows: 9
    // Hand-placed scene: glider, blinker, block, a toad and two fading cells.
    readonly property var aliveCells: [
        [3, 1], [4, 2], [2, 3], [3, 3], [4, 3],
        [10, 5], [11, 5], [12, 5],
        [17, 2], [18, 2], [17, 3], [18, 3],
        [23, 5], [24, 5], [25, 5], [22, 6], [23, 6], [24, 6],
        [27, 1], [27, 2], [27, 3]
    ]
    readonly property var dyingCells: [[3, 2], [2, 1], [11, 4], [11, 6], [26, 2]]

    implicitWidth: Kirigami.Units.gridUnit * 24
    implicitHeight: Kirigami.Units.gridUnit * 4.5
    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 4.5
    Layout.maximumWidth: Kirigami.Units.gridUnit * 30
    radius: 6
    color: bgColor
    clip: true
    border.width: 1
    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.2)

    onBgColorChanged: canvas.requestPaint()
    onDeadColorChanged: canvas.requestPaint()
    onAliveColorChanged: canvas.requestPaint()
    onShapeChanged: canvas.requestPaint()
    onFadeChanged: canvas.requestPaint()

    Component.onCompleted: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function mix(a, b, t) {
            return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1.0);
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const cell = Math.min(width / preview.cols, height / preview.rows);
            const ox = (width - cell * preview.cols) / 2;
            const oy = (height - cell * preview.rows) / 2;
            const round = preview.shape !== "Square";
            const dyingColor = mix(preview.deadColor, preview.aliveColor, 0.5);

            function drawCell(x, y, color) {
                ctx.fillStyle = color;
                const px = ox + x * cell;
                const py = oy + y * cell;
                if (round) {
                    ctx.beginPath();
                    ctx.arc(px + cell / 2, py + cell / 2, cell * 0.42, 0, Math.PI * 2);
                    ctx.fill();
                } else {
                    ctx.fillRect(px + 0.5, py + 0.5, cell - 1, cell - 1);
                }
            }

            for (let y = 0; y < preview.rows; ++y) {
                for (let x = 0; x < preview.cols; ++x) {
                    drawCell(x, y, preview.deadColor);
                }
            }

            if (preview.shape === "Go Board") {
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.07);
                ctx.lineWidth = 1;
                ctx.beginPath();
                for (let gx = 0; gx <= preview.cols; ++gx) {
                    ctx.moveTo(ox + gx * cell, oy);
                    ctx.lineTo(ox + gx * cell, oy + preview.rows * cell);
                }
                for (let gy = 0; gy <= preview.rows; ++gy) {
                    ctx.moveTo(ox, oy + gy * cell);
                    ctx.lineTo(ox + preview.cols * cell, oy + gy * cell);
                }
                ctx.stroke();
            }

            if (preview.fade) {
                for (let d = 0; d < preview.dyingCells.length; ++d) {
                    drawCell(preview.dyingCells[d][0], preview.dyingCells[d][1], dyingColor);
                }
            }
            for (let a = 0; a < preview.aliveCells.length; ++a) {
                drawCell(preview.aliveCells[a][0], preview.aliveCells[a][1], preview.aliveColor);
            }
        }
    }
}
