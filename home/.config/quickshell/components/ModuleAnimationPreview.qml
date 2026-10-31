import QtQuick
import Quickshell
import "../theme"
Item {
    id:root
    property var preset
    property real speed:100
    property real delay:18
    property bool opened:false
    implicitWidth:100;implicitHeight:62
    TimedSize {
        id:geometry
        targetWidth:root.opened?94:40
        targetHeight:root.opened?48:14
        profile:root.opened?root.preset.id:"theme"
        axisDelay:root.delay/100
        duration:Math.round(root.preset.duration*100/Math.max(25,root.speed))
        easing:root.preset.curve==="InOutCubic"?Easing.InOutCubic:root.preset.curve==="OutQuint"?Easing.OutQuint:Easing.OutCubic
    }
    Rectangle {
        anchors.centerIn:parent
        width:geometry.width;height:geometry.height
        radius:Math.min(12,height/2)
        color:Theme.accentIn(QsWindow.window)
    }
    Timer {interval:1300;running:root.visible&&(root.QsWindow.window?.visible??true);repeat:true;triggeredOnStart:true;onTriggered:root.opened=!root.opened}
}
