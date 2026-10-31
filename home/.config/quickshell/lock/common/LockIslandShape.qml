import QtQuick
import QtQuick.Shapes

// Shared by the secure session lock and SDDM so both use the same silhouette.
Rectangle {
    id: root
    objectName: "lock-island-shape"
    property bool notched: true
    property color rimColor: "#35ffffff"
    property real shoulder: Math.min(12, height/2)
    radius: height/2
    topLeftRadius: notched ? 0 : radius
    topRightRadius: notched ? 0 : radius
    border.color: rimColor
    border.width: notched ? 0 : 1
    Repeater {
        model: root.notched ? 2 : 0
        Item {
            required property int index
            x: index === 0 ? -width : root.width
            width: root.shoulder; height: root.shoulder
            transform: Scale { xScale: index === 0 ? -1 : 1; origin.x: root.shoulder/2 }
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: 0; fillColor: root.color
                    startX: 0; startY: 0
                    PathLine { x: root.shoulder; y: 0 }
                    PathAngleArc {
                        centerX: root.shoulder; centerY: root.shoulder
                        radiusX: root.shoulder; radiusY: root.shoulder
                        startAngle: -90; sweepAngle: -90
                    }
                    PathLine { x: 0; y: 0 }
                }
            }
        }
    }
}
