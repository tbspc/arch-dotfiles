import QtQuick
QtObject {
    id:root
    property bool enabled:false
    property real amplitude:2.8
    property int duration:420
    property real phase:1
    readonly property real offset:enabled?amplitude*Math.sin(phase*Math.PI*2.5)*Math.sin(phase*Math.PI)*Math.exp(-1.5*phase):0
    function restart():void {
        travel.stop()
        if(enabled&&duration>0)travel.restart()
        else phase=1
    }
    onEnabledChanged:restart()
    onAmplitudeChanged:if(enabled)restart()
    onDurationChanged:if(enabled)restart()
    readonly property NumberAnimation travel:NumberAnimation {target:root;property:"phase";from:0;to:1;duration:root.duration;easing.type:Easing.Linear}
}
