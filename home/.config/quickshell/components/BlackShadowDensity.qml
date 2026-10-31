import QtQuick
// Adjust the blurred alpha falloff and tint without blurring the live bar.
ShaderEffect {
    property var source
    property var cutout
    property color shadowInk:"#000000"
    property real falloffPower:1
    property real gain:1
    property real maskEnabled:0
    property var maskSource:maskEnabled>.5?cutout:source
    fragmentShader:Qt.resolvedUrl("../shaders/adjustable-shadow-density.frag.qsb")
}
