import QtQuick
NumberAnimation {
    id:root
    property int curve:Easing.OutCubic
    property real spring:1.70158
    property var customCurve:[]
    function configure():void {
        // Assigning bezierCurve changes Qt's easing type, so only write it
        // when custom curves are enabled. Otherwise restore the named curve.
        if(customCurve.length>=6&&customCurve.length%6===0) {
            easing.type=Easing.Bezier
            easing.bezierCurve=customCurve
        } else easing.type=curve
        if(customCurve.length===0)easing.overshoot=spring
    }
    onCurveChanged:configure()
    onSpringChanged:configure()
    onCustomCurveChanged:configure()
    onRunningChanged:if(running)configure()
    Component.onCompleted:configure()
}
