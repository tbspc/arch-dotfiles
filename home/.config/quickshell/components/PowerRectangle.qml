import QtQuick
// Preserve Qt's original circular renderer at power 2. Other exponents use
// an antialiased superellipse in the same bounds, without changing radius.
Item {
    id:root
    property color color:"transparent"
    property real radius:0
    property real topLeftRadius:radius
    property real topRightRadius:radius
    property real bottomLeftRadius:radius
    property real bottomRightRadius:radius
    property real roundingPower:2
    property alias border:plain.border
    Rectangle {
        id:plain
        anchors.fill:parent;visible:Math.abs(root.roundingPower-2)<.001
        color:root.color;radius:root.radius
        topLeftRadius:root.topLeftRadius;topRightRadius:root.topRightRadius
        bottomLeftRadius:root.bottomLeftRadius;bottomRightRadius:root.bottomRightRadius
    }
    ShaderEffect {
        anchors.fill:parent;visible:Math.abs(root.roundingPower-2)>=.001
        property color fillInk:root.color
        property color strokeInk:root.border.color
        property vector2d boxSize:Qt.vector2d(width,height)
        property vector4d radii:Qt.vector4d(root.topLeftRadius,root.topRightRadius,root.bottomRightRadius,root.bottomLeftRadius)
        property real power:Math.max(1,Math.min(8,root.roundingPower))
        property real strokeWidth:root.border.width
        fragmentShader:Qt.resolvedUrl("../shaders/power-rectangle.frag.qsb")
    }
}
