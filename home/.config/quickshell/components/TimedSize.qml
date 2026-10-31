import QtQuick

// Use Qt's native animation driver, so geometry advances on the same clock
// as opacity, carousel motion and the screen's refresh rate.
QtObject {
    id:root
    property real targetWidth:0
    property real targetHeight:0
    property int duration:380
    property int easing:Easing.OutCubic
    property string transitionKey:""
    property string profile:"theme"
    property real axisDelay:.18
    property real overshoot:1.70158
    property var bezierCurve:[]
    property var heightBezierCurve:[]
    readonly property int widthWait:profile==="height-first"?Math.round(duration*Math.max(0,Math.min(.6,axisDelay))):0
    readonly property int heightWait:profile==="width-first"?Math.round(duration*Math.max(0,Math.min(.6,axisDelay))):0
    readonly property int smoothEasing:[Easing.Linear,Easing.OutQuint,Easing.OutBack,Easing.InOutCubic,Easing.OutSine,Easing.InOutSine].includes(easing)?easing:Easing.OutCubic
    property real width:0
    property real height:0
    property real timeline:1
    property real fromWidth:0
    property real fromHeight:0
    property bool ready:false
    readonly property bool running:travel.running
    property int sampledFrames:0
    property real sampledTime:0
    property real longestFrame:0
    property bool frameStarted:false
    function frameStats():var {return {frames:sampledFrames,averageMs:sampledFrames?1000*sampledTime/sampledFrames:0,worstMs:1000*longestFrame,running:travel.running}}
    function snap():void {
        request.stop();travel.stop()
        width=targetWidth;height=targetHeight
        fromWidth=width;fromHeight=height;timeline=1
    }
    function retarget():void {
        if(!ready)return
        travel.stop()
        fromWidth=width;fromHeight=height
        if(duration<=0||Math.abs(width-targetWidth)+Math.abs(height-targetHeight)<.01){width=targetWidth;height=targetHeight;return}
        sampledFrames=0;sampledTime=0;longestFrame=0;frameStarted=false
        timeline=0
        travel.start()
    }
    onTargetWidthChanged:request.restart()
    onTargetHeightChanged:request.restart()
    onTransitionKeyChanged:request.restart()
    readonly property Timer request:Timer {interval:0;onTriggered:root.retarget()}
    readonly property ParallelAnimation travel:ParallelAnimation {
        NumberAnimation {target:root;property:"timeline";from:0;to:1;duration:root.duration;easing.type:Easing.Linear}
        SequentialAnimation {
            PauseAnimation {duration:root.widthWait}
            ConfiguredNumberAnimation {target:root;property:"width";to:root.targetWidth;duration:Math.max(0,root.duration-root.widthWait);curve:root.smoothEasing;customCurve:root.bezierCurve;spring:root.overshoot}
        }
        SequentialAnimation {
            PauseAnimation {duration:root.heightWait}
            ConfiguredNumberAnimation {target:root;property:"height";to:root.targetHeight;duration:Math.max(0,root.duration-root.heightWait);curve:root.smoothEasing;customCurve:root.heightBezierCurve.length?root.heightBezierCurve:root.bezierCurve;spring:root.overshoot}
        }
    }
    readonly property FrameAnimation frameCounter:FrameAnimation {
        running:travel.running
        onTriggered:{if(root.frameStarted){root.sampledFrames++;root.sampledTime+=frameTime;root.longestFrame=Math.max(root.longestFrame,frameTime)}else root.frameStarted=true}
    }
    Component.onCompleted:{width=targetWidth;height=targetHeight;ready=true}
}
