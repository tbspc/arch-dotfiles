import QtQuick
Rectangle {
    id:root
    property color ink:"#ffffff"
    radius:width/2;color:Qt.alpha(ink,.13);border.width:1.5;border.color:Qt.alpha(ink,.4);antialiasing:true
    Rectangle{width:parent.width*.21;height:width;radius:width/2;x:(parent.width-width)/2;y:parent.height*.29;color:root.ink;antialiasing:true}
    Rectangle{width:parent.width*.36;height:parent.height*.19;topLeftRadius:width/2;topRightRadius:width/2;bottomLeftRadius:1;bottomRightRadius:1;x:(parent.width-width)/2;y:parent.height*.52;color:root.ink;antialiasing:true}
}
