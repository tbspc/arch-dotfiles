import QtQuick

// The padlock remains fully open until its fade-in finishes, pauses, then
// closes. This runs inside the secure lock and never delays screen coverage.
QtObject {
    id:root
    property bool enabled:true
    property int revealDuration:280
    property int openHold:100
    property int closeDuration:220
    property real lift:1
    readonly property bool running:sequence.running
    function reset():void { sequence.stop();root.lift=1 }
    function start():void {
        root.reset()
        if(!root.enabled){root.lift=0;return}
        sequence.start()
    }
    readonly property SequentialAnimation sequence:SequentialAnimation {
        PauseAnimation{duration:Math.max(0,root.revealDuration)+Math.max(0,root.openHold)}
        NumberAnimation{
            target:root;property:"lift";from:1;to:0
            duration:Math.max(0,root.closeDuration)
            easing.type:Easing.InOutCubic
        }
    }
}
