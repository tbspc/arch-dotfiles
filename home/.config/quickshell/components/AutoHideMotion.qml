import QtQuick
QtObject {
    id:root
    property bool hidden:false
    property bool animated:true
    property string style:"slide-fade"
    property int showDuration:340
    property int hideDuration:280
    property real distance:56
    property bool ready:false
    property real progress:hidden?0:1
    readonly property bool running:travel.running
    readonly property real bounded:Math.max(0,Math.min(1,progress))
    readonly property real offset:style==="fade"||style==="none"?0:-(1-progress)*distance*(style==="lift"?.55:1)
    readonly property real alpha:style==="slide"||style==="spring"?(progress>.001?1:0):bounded
    readonly property real zoom:style==="lift"?.98+.02*bounded:1
    Behavior on progress {
        enabled:root.ready && root.animated && root.style!=="none"
        NumberAnimation {
            id:travel
            duration:root.hidden?root.hideDuration:root.showDuration
            easing.type:root.style==="spring"&&!root.hidden?Easing.OutBack:root.hidden?Easing.InOutCubic:Easing.OutCubic
            easing.overshoot:.55
        }
    }
    Component.onCompleted:root.ready=true
}
