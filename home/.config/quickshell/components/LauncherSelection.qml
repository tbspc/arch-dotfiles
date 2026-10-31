import QtQuick
import Quickshell
import "../theme"
import "../services"
Rectangle {
    id:root
    property var appearance:LauncherPresetService.style
    radius:appearance.rowRadius
    color:appearance.highlightStyle==="outline"||appearance.highlightStyle==="none"?"transparent":appearance.highlightColor||Qt.alpha(appearance.highlightStyle==="accent"?Theme.accentIn(QsWindow.window):Theme.text,appearance.highlightOpacity/100)
    border.width:1
    border.color:appearance.highlightStyle==="none"?"transparent":Qt.alpha(appearance.highlightStyle==="outline"?Theme.accentIn(QsWindow.window):Theme.text,appearance.borderOpacity/100)
    Rectangle{objectName:"design:LauncherPanel:15";x:2;anchors.verticalCenter:parent.verticalCenter;visible:root.appearance.indicatorStyle!=="none";width:root.appearance.indicatorWidth;height:root.appearance.indicatorStyle==="dot"?width:parent.height*root.appearance.indicatorHeight/100;radius:width/2;color:Theme.accentIn(QsWindow.window)}
}
