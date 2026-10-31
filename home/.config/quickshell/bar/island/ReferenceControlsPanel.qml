import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import "../../theme"
import "../../services"

Item {
    id:root
    signal closed()
    signal panelRequested(string panel)
    signal settingsRequested()
    property bool preview:false
    readonly property color accent:Theme.moduleColour("controls","accent",Theme.accent)
    readonly property color ink:Theme.text
    readonly property color muted:Theme.paletteMuted
    readonly property color onAccent:Theme.accentText
    readonly property color card:"#181715"
    readonly property real k:width/483
    implicitWidth:483
    implicitHeight:490
    component ToggleTile:Rectangle {
        id:tile
        property string tileKey:"wifi"
        property bool round:false
        readonly property var entry:ControlsService.tileOf(tileKey)
        readonly property bool on:entry?.active??false
        height:60*root.k;radius:height/2
        color:round&&on?root.accent:root.card
        border.width:1;border.color:Qt.alpha(root.ink,.08)
        Rectangle {
            x:10*root.k;y:10*root.k;width:40*root.k;height:width;radius:width/2
            color:tile.on?root.accent:"#33302d"
            visible:!tile.round
        }
        Text {
            x:tile.round?0:10*root.k;y:tile.round?0:10*root.k
            width:tile.round?parent.width:40*root.k;height:tile.round?parent.height:40*root.k
            horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter
            visible:tile.tileKey!=="wifi"
            text:tile.tileKey==="lock"?"󰌾":tile.tileKey==="nightlight"?"󰖔":tile.tileKey==="focus"?"󰍶":tile.entry?.icon||""
            font.family:Theme.fontMono;font.pixelSize:17*root.k
            color:tile.on?root.onAccent:root.ink
        }
        Canvas {
            id:wifiGlyph
            visible:tile.tileKey==="wifi";x:20*root.k;y:20*root.k;width:20*root.k;height:20*root.k
            onPaint:{const c=getContext("2d");c.reset();c.scale(width/20,height/20);c.strokeStyle=tile.on?String(root.onAccent):String(root.ink);c.fillStyle=c.strokeStyle;c.lineWidth=1.9;c.lineCap="round";for(let r of [4,7,10]){c.beginPath();c.arc(10,16,r,Math.PI*1.23,Math.PI*1.77);c.stroke()}c.beginPath();c.arc(10,16,1.3,0,Math.PI*2);c.fill()}
            Connections{target:tile;function onOnChanged(){wifiGlyph.requestPaint()}}
            Connections{target:root;function onInkChanged(){wifiGlyph.requestPaint()} function onOnAccentChanged(){wifiGlyph.requestPaint()}}
        }
        Column {
            x:62*root.k;anchors.verticalCenter:parent.verticalCenter;visible:!tile.round;width:parent.width-x-8;spacing:0
            Text {text:tile.entry?.label||"";font.family:Theme.fontFamily;font.pixelSize:14*root.k;font.weight:Font.DemiBold;color:root.ink}
            Text {width:parent.width;elide:Text.ElideRight;text:tile.tileKey==="focus"||tile.tileKey==="game"?(tile.on?"On":"Off"):tile.tileKey==="bluetooth"?(tile.on?"On":"Off"):tile.entry?.detail||"";font.family:Theme.fontFamily;font.pixelSize:12*root.k;color:root.muted}
        }
        MouseArea {
            anchors.fill:parent;enabled:!root.preview;cursorShape:Qt.ArrowCursor
            onClicked:{if(tile.tileKey==="lock"){root.closed();LockService.lock()}else if(tile.tileKey==="wifi"||tile.tileKey==="bluetooth")root.panelRequested(tile.entry.panel);else tile.entry?.action()}
        }
        MouseArea {
            x:10*root.k;y:10*root.k;width:40*root.k;height:width;z:2
            visible:["wifi","bluetooth"].includes(tile.tileKey)
            enabled:visible&&!root.preview&&(tile.entry?.available??true)
            cursorShape:Qt.ArrowCursor
            onClicked:tile.entry?.action()
        }
    }
    component Level:Rectangle {
        id:level
        property string label:"Sound"
        property string glyph:"󰕾"
        property real value:50
        property bool available:true
        signal moved(real value)
        signal details()
        height:60*root.k;radius:24*root.k;color:root.card;border.width:1;border.color:Qt.alpha(root.ink,.08)
        Text {x:14*root.k;y:6*root.k;text:level.label;font.family:Theme.fontFamily;font.pixelSize:13*root.k;font.weight:Font.DemiBold;color:root.ink}
        Rectangle {x:parent.width-35*root.k;y:4*root.k;width:22*root.k;height:width;radius:width/2;color:"#272520"
            Text {anchors.centerIn:parent;text:"›";font.pixelSize:18*root.k;color:root.muted}
            MouseArea {anchors.fill:parent;enabled:!root.preview;onClicked:level.details()}
        }
        Controls.Slider {
            id:slider
            x:12*root.k;y:30*root.k;width:parent.width-24*root.k;height:24*root.k
            from:0;to:100;value:level.value;enabled:level.available&&!root.preview
            leftPadding:0;rightPadding:0;topPadding:0;bottomPadding:0
            onMoved:level.moved(value)
            handle:Item{}
            background:Rectangle {radius:height/2;color:"#0b0a09";height:slider.height;width:slider.width
                Rectangle {height:parent.height;width:Math.max(height,slider.visualPosition*parent.width);radius:height/2;color:root.accent}
                Canvas {
                    id:speakerGlyph
                    visible:level.label==="Sound";x:6*root.k;y:4*root.k;width:16*root.k;height:16*root.k
                    onPaint:{const c=getContext("2d");c.reset();c.scale(width/16,height/16);c.strokeStyle=String(root.onAccent);c.lineWidth=1.35;c.lineCap="round";c.lineJoin="round";c.beginPath();c.moveTo(2,6);c.lineTo(5,6);c.lineTo(8.5,3.5);c.lineTo(8.5,12.5);c.lineTo(5,10);c.lineTo(2,10);c.closePath();c.stroke();if(AudioService.muted){c.beginPath();c.moveTo(11,6);c.lineTo(14,10);c.moveTo(14,6);c.lineTo(11,10);c.stroke()}else{for(let r of [4,6.5]){c.beginPath();c.arc(8,8,r,-.7,.7);c.stroke()}}}
                    Connections{target:AudioService;function onMutedChanged(){speakerGlyph.requestPaint()}}
                    Connections{target:root;function onOnAccentChanged(){speakerGlyph.requestPaint()}}
                }
                Text {visible:level.label!=="Sound";x:9*root.k;anchors.verticalCenter:parent.verticalCenter;text:level.glyph;font.family:Theme.fontMono;font.pixelSize:16*root.k;color:root.onAccent}
            }
        }
    }
    ToggleTile{x:0;y:0;width:201*root.k;tileKey:"wifi"}
    ToggleTile{x:212*root.k;y:0;width:201*root.k;tileKey:"focus"}
    ToggleTile{x:424*root.k;y:0;width:60*root.k;tileKey:"lock";round:true}
    ToggleTile{x:0;y:71*root.k;width:201*root.k;tileKey:"bluetooth"}
    ToggleTile{x:212*root.k;y:71*root.k;width:201*root.k;tileKey:"game"}
    ToggleTile{x:424*root.k;y:71*root.k;width:60*root.k;tileKey:"nightlight";round:true}
    Level{x:0;y:142*root.k;width:parent.width;label:"Sound";glyph:AudioService.icon;value:AudioService.volume;available:AudioService.ready;onMoved:value=>AudioService.setVolume(Math.round(value));onDetails:root.panelRequested("sound")}
    Level{x:0;y:213*root.k;width:parent.width;label:"Display";glyph:"󰃠";value:BrightnessService.percent;available:BrightnessService.available;onMoved:value=>BrightnessService.setPercent(Math.max(1,Math.round(value)));onDetails:root.panelRequested("brightness")}
    Rectangle {
        y:284*root.k;width:parent.width;height:Math.max(100*root.k,parent.height-y);radius:24*root.k;color:root.card;border.width:1;border.color:Qt.alpha(root.ink,.08)
        Text {x:14*root.k;y:10*root.k;text:"Notifications";font.family:Theme.fontFamily;font.pixelSize:12*root.k;color:root.muted}
        Text {anchors.right:parent.right;anchors.rightMargin:14*root.k;y:10*root.k;text:"Clear all";font.family:Theme.fontFamily;font.pixelSize:12*root.k;color:root.muted
            MouseArea{anchors.fill:parent;anchors.margins:-4;enabled:!root.preview;onClicked:NotificationService.clearHistory()}
        }
        ListView {
            x:12*root.k;y:36*root.k;width:parent.width-24*root.k;height:parent.height-y-12*root.k;clip:true;spacing:5*root.k
            model:root.preview?[{appName:"Music",summary:"Now playing",body:"Your notifications appear here"},{appName:"System",summary:"Theme",body:"Palette applied"}]:NotificationService.history
            delegate:Rectangle {
                id:note
                required property var modelData
                width:ListView.view.width;height:67*root.k;radius:18*root.k;color:"#272421"
                Rectangle{x:12*root.k;y:12*root.k;width:30*root.k;height:width;radius:width/2;color:Qt.alpha(root.accent,.18)
                    Text{anchors.centerIn:parent;text:(note.modelData.appName||"N").slice(0,1).toUpperCase();font.pixelSize:11*root.k;font.bold:true;color:root.accent}
                }
                Column {x:54*root.k;y:9*root.k;width:parent.width-x-28*root.k;spacing:0
                    Text{width:parent.width;text:note.modelData.appName||"Notification";elide:Text.ElideRight;font.family:Theme.fontFamily;font.pixelSize:12*root.k;color:root.muted}
                    Text{width:parent.width;text:note.modelData.summary||"";elide:Text.ElideRight;font.family:Theme.fontFamily;font.pixelSize:13*root.k;font.weight:Font.DemiBold;color:root.ink}
                    Text{width:parent.width;text:note.modelData.body||"";textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Theme.fontFamily;font.pixelSize:12*root.k;color:root.muted}
                }
                Text {anchors.right:parent.right;anchors.rightMargin:12*root.k;y:8*root.k;text:"×";font.pixelSize:18*root.k;color:root.muted
                    MouseArea{anchors.fill:parent;anchors.margins:-3;enabled:!root.preview;onClicked:NotificationService.remove(note.modelData)}
                }
                TapHandler {enabled:!root.preview;onTapped:if(NotificationService.open(note.modelData))root.closed()}
            }
        }
        Text{anchors.centerIn:parent;visible:!root.preview&&NotificationService.history.length===0;text:"No notifications";font.family:Theme.fontFamily;font.pixelSize:13*root.k;color:root.muted}
    }
    Component.onCompleted:if(!preview){NetworkService.refresh();BrightnessService.refresh()}
}
