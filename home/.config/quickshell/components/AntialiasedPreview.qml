import QtQuick

// Filter the image normally, then evaluate the rounded edge at the final
// transformed pixel size. The border and image share exactly one coverage mask.
Item {
    id:root
    property color color:"transparent"
    property real radius:12
    property color borderColor:"transparent"
    property real borderWidth:1
    default property alias content:body.data
    Item {id:body;anchors.fill:parent}
    ShaderEffectSource {
        id:sample
        sourceItem:body
        hideSource:true
        live:true
        visible:false
        smooth:true
    }
    ShaderEffect {
        anchors.fill:parent
        property variant source:sample
        property vector2d boxSize:Qt.vector2d(width,height)
        property real cornerRadius:root.radius
        property real lineWidth:root.borderWidth
        property color fillInk:root.color
        property color rimInk:root.borderColor
        fragmentShader:Qt.resolvedUrl("../shaders/preview-rounded.frag.qsb")
    }
}
