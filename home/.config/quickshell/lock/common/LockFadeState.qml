import QtQuick

// One fade per secure lock entry. No timer/callback can restart it when a
// screenshot becomes ready, and no entry fade runs before secure coverage.
QtObject {
    id:root
    property bool locked:false
    property bool secure:false
    property bool leaving:false
    property bool directDesktop:false
    property bool presented:true
    property int duration:420
    property int curve:Easing.InOutSine
    property real value:0
    property bool ready:false
    readonly property bool running:motion.running
    function sync():void {
        if(!root.ready)return
        if(!root.locked || (!root.secure&&!root.leaving) || (!root.presented&&!root.leaving)){
            motion.stop();root.value=0;return
        }
        const target=root.leaving&&!root.directDesktop?0:1
        if(motion.running&&motion.to===target)return
        if(root.value===target)return
        motion.stop();motion.from=root.value;motion.to=target;motion.start()
    }
    onLockedChanged:sync()
    onSecureChanged:sync()
    onPresentedChanged:sync()
    onLeavingChanged:sync()
    onDirectDesktopChanged:sync()
    Component.onCompleted:{root.ready=true;root.sync()}
    readonly property NumberAnimation motion:NumberAnimation {
        target:root;property:"value"
        duration:Math.max(0,root.duration)
        easing.type:root.curve
    }
}
