import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../settings"
import "../bar/island"
import "../services"

Item {
    id: root
    property string kind: "bar"
    property string moduleId: "notes"
    property var values: ({})
    property bool animate: false
    implicitHeight: 116
    Loader {
        anchors.fill: parent
        sourceComponent: root.kind === "bar" || (root.kind === "modules" && root.moduleId === "bar") ? bar
            : root.kind === "launcher" || (root.kind === "modules" && root.moduleId === "launcher") ? launcher
            : root.kind === "designs" ? design : root.kind === "setup" ? setup
            : root.kind === "shellmotion" ? shellMotion : root.kind === "windowmotion" ? windowMotion
            : root.kind==="modules"&&["appearance","palette"].includes(root.moduleId)&&["reference","gallery"].includes(root.values.options?.wallpaperPickerDesign||root.values.options?.themePickerDesign)?wallpaperDesign : root.kind === "lockscreen" ? lockDesign : root.kind==="modules"&&root.moduleId==="controls"&&root.values.options?.centreDesign==="reference"?controlDesign : root.kind === "lockmotion" ? lockMotion : (root.kind === "barcolour" || root.kind === "macglass") ? material : modulePreview
    }
    Component {id:lockDesign;LockDesignPreview{configuration:Object.assign({},LockStyleService.values,root.values);showGuides:false;interactive:false;mode:"password"}}
    Component {id:wallpaperDesign;Item {Rectangle {
        readonly property bool compact:root.values.options?.wallpaperPickerDesign==="gallery"
        readonly property int frameWidth:compact?1016:808
        readonly property int frameHeight:compact?232:224
        readonly property int inset:16
        anchors.centerIn:parent;width:Math.min(parent.width-8,220);height:width*frameHeight/frameWidth;radius:10;color:"#000000"
        ReferenceAppearancePanel{compact:parent.compact;x:parent.width*parent.inset/parent.frameWidth;y:x;width:parent.frameWidth-2*parent.inset;height:parent.frameHeight-2*parent.inset;scale:parent.width/parent.frameWidth;transformOrigin:Item.TopLeft;page:root.moduleId==="palette"?"palette":"wallpaper";preview:true}
    }}}

    Component {id:controlDesign;Item{Rectangle{anchors.centerIn:parent;width:116;height:116;radius:8;color:"#000000";ReferenceControlsPanel{width:483;height:490;scale:100/483;transformOrigin:Item.TopLeft;x:8;y:7;preview:true}}}}
    Component {
        id:material
        Rectangle {
            radius:10;color:"#283444";clip:true
            Image { anchors.fill:parent;source:WallpaperService.currentWallpaper?"file://"+WallpaperService.currentWallpaper:"";sourceSize:Qt.size(360,160);fillMode:Image.PreserveAspectCrop;asynchronous:true }
            Rectangle {
                anchors.centerIn:parent;width:parent.width*.8;height:parent.height*.64;radius:18
                color:root.values.surfaceStyle==="classic"?(root.values.floatingBarSurface==="grey"?"#141414":"#000000"):Theme.groundOf(root.values.surfaceStyle)
                border.width:1;border.color:Theme.rimOf(root.values.surfaceStyle)
                Column { anchors.centerIn:parent;spacing:7
                    Text { anchors.horizontalCenter:parent.horizontalCenter;text:"9:41";font.family:Theme.fontFamily;font.pixelSize:18;color:Theme.text }
                    Rectangle { width:62;height:4;radius:2;color:Theme.accent }
                }
            }
        }
    }
    Component { id: bar; IslandPresetPreview { values: root.kind === "modules" ? root.values.island || {} : root.values } }
    Component { id: launcher; LauncherPresetPreview { values: root.kind === "modules" ? root.values.launcher || {} : root.values } }
    Component { id: setup; IslandPresetPreview { values: root.values.settings || {}; } }
    Component { id: shellMotion; IslandMotionPreview { preset: root.values; animate: root.animate } }
    Component { id: windowMotion; MotionPreview { preset: root.values; animate: root.animate } }
    Component {
        id: design
        Rectangle {
            color: root.values.background || "#181b21"; radius: 10
            readonly property bool topNavigation: root.values.navigation === "top"
            Rectangle { x: 6; y: 6; width: parent.topNavigation ? parent.width - 12 : parent.width * .27; height: parent.topNavigation ? 20 : parent.height - 12; radius: 5; color: root.values.sidebarBackground || "#252a34"
                Column { anchors.fill: parent; anchors.margins: 5; spacing: 5
                    Repeater { model: 4; Rectangle { required property int index; width: parent.width; height: 6; radius: 2; color: Qt.alpha(Theme.accentIn(QsWindow.window), index === 1 ? .75 : .18) } }
                }
            }
            Column {
                x: parent.topNavigation ? 12 : parent.width * .27 + 14; y: parent.topNavigation ? 36 : 14
                width: parent.width - x - 12; spacing: 8
                Repeater { model: 3; Rectangle { width: parent.width; height: 18; radius: 5; color: root.values.cardBackground || "#292f3a"; border.width: 1; border.color: root.values.borderColor || "#394050" } }
            }
        }
    }
    Component {
        id: modulePreview
        Item {
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width - 16, parent.width * .88 * (root.values.appearance?.widthScale || 100) / 100)
                height: Math.min(parent.height - 12, parent.height * .82 * (root.values.appearance?.heightScale || 100) / 100)
                radius: Math.min(height / 3, root.values.rounding ?? 18)
                color: "#080a10"; border.width: 1; border.color: Qt.alpha(Theme.accentIn(QsWindow.window), .35)
                Column { anchors.fill: parent; anchors.margins: 14; spacing: 10
                    Rectangle { width: parent.width * .42; height: 8; radius: 4; color: Theme.text }
                    Rectangle { width: parent.width; height: 6; radius: 3; color: Qt.alpha(Theme.text, .12)
                        Rectangle { width: parent.width * .68; height: parent.height; radius: 3; color: Theme.accentIn(QsWindow.window) }
                    }
                    Rectangle { width: parent.width * .70; height: 5; radius: 3; color: Qt.alpha(Theme.text, .25) }
                }
            }
        }
    }
    Component {
        id: lockMotion
        Rectangle {
            color: Qt.alpha(Theme.accentIn(QsWindow.window), .12); radius: 10; clip: true
            property real phase: 1
            readonly property string style:root.values.lockAnimation || "fade"
            Rectangle { width:parent.width;height:parent.height;color:Qt.alpha(Theme.accentIn(QsWindow.window), .14)
                y:parent.style==="bar-slide"?-height+parent.phase*height:parent.style==="soft-slide"?(1-parent.phase)*14:0
                opacity:parent.style==="none" || parent.style==="bar-slide"?1:parent.phase
                Text { anchors.centerIn: parent; text: "9:41"; font.family: Theme.fontDisplay; font.pixelSize: 30; font.weight: Font.Bold; color: Theme.text }
            }
            NumberAnimation on phase { from: 0; to: 1; duration: Math.max(150, (root.values.lockAnimationDuration || 400)*100/(root.values.lockAnimationSpeed || 100)); running: root.animate && root.values.lockAnimation!=="none"; loops: Animation.Infinite; easing.type:root.values.lockAnimationMovement==="quint"?Easing.OutQuint:root.values.lockAnimationMovement==="glide"?Easing.OutCubic:root.values.lockAnimationMovement==="bounce"?Easing.OutBounce:root.values.lockAnimationMovement==="spring"?Easing.OutBack:Easing.InOutCubic }
        }
    }
}
