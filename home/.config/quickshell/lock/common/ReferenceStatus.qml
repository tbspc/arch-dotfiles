import QtQuick
Item {
    id:root
    property int percent:80
    property bool batteryAvailable:true
    property bool wifiVisible:true
    property color ink:"#ffffff"
    implicitWidth:58;implicitHeight:16
    Rectangle {
        visible:root.batteryAvailable;x:0;y:1;width:25;height:14;radius:3;color:"transparent";border.width:1.2;border.color:root.ink;opacity:.8
        Rectangle{x:2;y:2;height:10;width:21*root.percent/100;radius:1;color:root.ink;opacity:.8}
        Text{anchors.centerIn:parent;text:root.percent;font.family:"SF Pro Text";font.pixelSize:10;font.weight:Font.Bold;color:"#18483d"}
        Rectangle{x:26;y:4;width:2;height:6;radius:1;color:root.ink}
    }
    Canvas {
        id:wifi;x:41;y:1;width:16;height:14;visible:root.wifiVisible
        onPaint:{const c=getContext("2d");c.reset();c.strokeStyle=root.ink;c.fillStyle=root.ink;c.lineWidth=1.7;c.lineCap="round";for(let r of [4,7,10]){c.beginPath();c.arc(8,13,r,Math.PI*1.23,Math.PI*1.77);c.stroke()}c.beginPath();c.arc(8,12,1.2,0,Math.PI*2);c.fill()}
        Connections{target:root;function onInkChanged(){wifi.requestPaint()}}
    }
}
