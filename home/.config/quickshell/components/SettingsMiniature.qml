import QtQuick
Rectangle {
    id:root
    required property var colours
    property color accent:"#a2d0ad"
    color:colours.background||"#171c17"
    radius:7
    clip:true
    Rectangle {
        width:parent.width*.26
        height:parent.height
        color:root.colours.sidebarBackground||"#121712"
        Column {
            anchors.fill:parent
            anchors.margins:6
            spacing:6
            Repeater {
                model:5
                Rectangle {
                    required property int index
                    width:parent.width
                    height:4
                    radius:2
                    color:index===1?root.accent:root.colours.mutedColor||"#acb6a5"
                    opacity:index===1?1:.45
                }
            }
        }
    }
    Column {
        x:parent.width*.3
        y:12
        width:parent.width*.64
        spacing:8
        Rectangle {width:parent.width*.6;height:6;radius:2;color:root.colours.textColor||"#edf1e9"}
        Rectangle {width:parent.width;height:3;radius:1;color:root.colours.mutedColor||"#acb6a5";opacity:.55}
        Rectangle {width:parent.width;height:3;radius:1;color:root.colours.mutedColor||"#acb6a5";opacity:.55}
        Row {
            spacing:5
            Rectangle {width:root.width*.25;height:18;radius:3;color:root.accent}
            Rectangle {width:root.width*.22;height:18;radius:3;color:root.colours.fieldBackground||"#293127";border.width:1;border.color:root.colours.borderColor||"#364033"}
        }
        Rectangle {width:parent.width;height:Math.max(10,root.height-91);radius:4;color:root.colours.cardBackground||"#20271f";border.width:1;border.color:root.colours.borderColor||"#364033"}
    }
}
