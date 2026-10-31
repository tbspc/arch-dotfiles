import QtQuick
import QtQuick.Shapes
// Clean alpha masks preserve the reference silhouette without baked image shading.
Item {
    id:root
    property real charge:1
    property real fillOpacity:1
    property real emptyOpacity:0.24
    property real tipOpacity:0.32
    property bool charging:false
    property bool percentage:false
    property string percentageText:"100%"
    property string textFont:"Sans Serif"
    property int textSize:11
    property color ink:"#6db5c0"
    property color boltInk:"#f4ffff"
    property color textColour:ink
    implicitWidth:percentage?39+readout.implicitWidth:43
    implicitHeight:26
    Image {id:bodyShape;source:Qt.resolvedUrl("../../assets/battery/reference-body-mask.png");visible:false;smooth:true}
    Image {id:tipShape;source:Qt.resolvedUrl("../../assets/battery/reference-cap-mask.png");visible:false;smooth:true}
    ShaderEffect {
        property var bodyMask:bodyShape
        property var tipMask:tipShape
        width:43;height:26
        property color ink:root.ink
        property real charge:root.charge
        property real fillOpacity:root.fillOpacity
        property real emptyOpacity:root.emptyOpacity
        property real tipOpacity:root.tipOpacity
        fragmentShader:Qt.resolvedUrl("../../shaders/reference-battery-clean-mask.frag.qsb")
    }
    Shape {
        visible:root.charging
        x:13.5;y:7.5;width:6;height:10
        preferredRendererType:Shape.CurveRenderer
        ShapePath {
            strokeWidth:0;strokeColor:"transparent";fillColor:root.boltInk
            startX:4.2;startY:0
            PathLine {x:0;y:5.6}
            PathLine {x:2.6;y:5.6}
            PathLine {x:1.7;y:10}
            PathLine {x:6;y:4}
            PathLine {x:3.4;y:4}
            PathLine {x:4.2;y:0}
        }
    }
    Text {id:readout;visible:root.percentage;x:39;anchors.verticalCenter:parent.verticalCenter;text:root.percentageText;font.family:root.textFont;font.pixelSize:root.textSize;font.weight:Font.DemiBold;color:root.textColour}
}
