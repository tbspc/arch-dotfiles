import QtQuick
import "../components"
// Only the bar's opaque silhouette gets the independent clock-to-lock fade.
// Wallpaper and shadow stay in the complete desktop fade below this overlay.
Item {
    id:root
    property url source
    property real fullHeight:height
    property real barX:0
    property real barY:0
    property real barWidth:0
    property real barHeight:0
    property real cornerRadius:0
    property real cornerPower:2
    property real shoulder:0
    property bool notched:true
    Item {
        id:desktopSlice
        width:root.width;height:root.height
        visible:false;layer.enabled:true;clip:true
        Image {width:root.width;height:root.fullHeight;source:root.source;fillMode:Image.PreserveAspectCrop;asynchronous:false;cache:true}
    }
    Item {
        id:silhouette
        width:root.width;height:root.height
        visible:false;layer.enabled:true
        PowerRectangle {
            x:root.barX;y:root.barY;width:root.barWidth;height:root.barHeight
            color:"white";radius:root.cornerRadius;roundingPower:root.cornerPower
            topLeftRadius:root.notched?0:radius;topRightRadius:root.notched?0:radius
        }
        NotchFillet {x:root.barX-width;y:root.barY;width:root.shoulder;height:width;mirrored:true;color:"white";visible:root.notched}
        NotchFillet {x:root.barX+root.barWidth;y:root.barY;width:root.shoulder;height:width;color:"white";visible:root.notched}
    }
    ShaderEffect {
        anchors.fill:parent
        property var source:desktopSlice
        property var maskSource:silhouette
        fragmentShader:Qt.resolvedUrl("../shaders/lock-bar-capture-mask.frag.qsb")
    }
}
