import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"
import "../../theme"
Item {
    id:root
    property string kind:"none"
    property bool alignRight:false
    property bool compact:false
    property real labelSize:12
    property real iconSize:14
    property bool preview:false
    readonly property bool watchWeather:visible&&!preview&&kind==="weather"
    property bool weatherSubscribed:false
    function syncWeather():void {
        if(watchWeather&&!weatherSubscribed){WeatherService.subscribe();weatherSubscribed=true}
        else if(!watchWeather&&weatherSubscribed){WeatherService.release();weatherSubscribed=false}
    }
    onWatchWeatherChanged:syncWeather()
    Component.onCompleted:syncWeather()
    Component.onDestruction:if(weatherSubscribed)WeatherService.release()
    property real reveal:kind==="none"||kind==="media"&&SettingsService.islandHoverMediaAutoHide&&!MediaService.playing?0:1
    Behavior on reveal {NumberAnimation {duration:Theme.durationFast;easing.type:Easing.OutCubic}}
    SystemClock {id:clock;enabled:root.visible&&root.kind==="date";precision:SystemClock.Minutes}
    readonly property string label:{
        switch(kind){
        case "desktop":return Tr.t("Desktop")
        case "weather":return WeatherService.available?WeatherService.temperature+"° · "+WeatherService.description:Tr.t("Weather")
        case "notifications":return SettingsService.doNotDisturb?Tr.t("Quiet mode"):NotificationService.history.length?NotificationService.history.length+" "+Tr.t("notifications"):Tr.t("All caught up")
        case "chatgpt":return "ChatGPT"
        case "date":return Qt.formatDateTime(clock.date,"ddd, d MMM")
        case "network":return NetworkService.connectionName
        case "battery":return BatteryService.available?BatteryService.percent+"%"+(BatteryService.pluggedIn?" · "+Tr.t("Charging"):""):Tr.t("Battery")
        case "notes":return Tr.t("Notes")
        case "launcher":return Tr.t("Search apps")
                case "tasks":return Tr.t("Tasks")
        case "timer":return Tr.t("Timer")
        default:return ""
        }
    }
    readonly property string glyph:{
        switch(kind){
        case "desktop":return "•"
        case "weather":return WeatherService.glyph||"󰖐"
        case "notifications":return SettingsService.doNotDisturb?"󰂛":"󰂚"
        case "date":return "󰃭"
        case "network":return NetworkService.wiredConnected?"󰈀":"󰖩"
        case "battery":return BatteryService.pluggedIn?"󰂄":"󰁹"
        case "notes":return "󰎞"
        case "launcher":return "󰍉"
                case "tasks":return "󰄬"
        case "timer":return "󰔟"
        default:return ""
        }
    }
    function activate():void {
        if(preview)return
        switch(kind){
        case "desktop":ModuleService.togglePanel("overview");break
        case "chatgpt":LauncherService.launchDesktop("chatgpt");break
        case "weather":ModuleService.activate("weather");break
        case "notifications":ModuleService.activate("notifications");break
        case "date":ModuleService.togglePanel("summary");break
        case "network":ModuleService.activate("network");break
        case "battery":ModuleService.activate("battery");break
        case "notes":ModuleService.togglePanel("notes");break
        case "launcher":ModuleService.togglePanel("launcher");break
                case "tasks":ModuleService.togglePanel("tasks");break
        case "timer":ModuleService.activate("timer");break
        }
    }
    Item {
        anchors.fill:parent;opacity:root.reveal;visible:opacity>.001;enabled:!root.preview&&root.reveal>.5
        RowLayout {
            visible:root.kind==="media"
            anchors.left:root.alignRight?undefined:parent.left
            anchors.right:root.alignRight?parent.right:undefined
            height:parent.height;width:Math.min(parent.width,implicitWidth);spacing:3
            Image {visible:!root.compact&&MediaService.artUrl!=="";source:MediaService.artUrl;Layout.preferredWidth:18;Layout.preferredHeight:18;sourceSize.width:36;sourceSize.height:36;fillMode:Image.PreserveAspectCrop;asynchronous:true}
            Text {visible:!root.compact;Layout.fillWidth:true;Layout.minimumWidth:0;text:MediaService.title||Tr.t("No media playing");font.family:Theme.fontFamily;font.pixelSize:root.labelSize;font.weight:Font.DemiBold;color:Theme.moduleColour("media","foreground",Theme.text);elide:Text.ElideRight}
            IconButton {icon:"󰒮";implicitWidth:24;implicitHeight:24;enabled:!root.preview&&MediaService.canPrevious;opacity:enabled?1:.35;iconColor:Theme.moduleColour("media","accent",Theme.accent);onClicked:MediaService.previous()}
            IconButton {icon:MediaService.playing?"󰏤":"󰐊";implicitWidth:24;implicitHeight:24;enabled:!root.preview&&MediaService.canToggle;opacity:enabled?1:.35;iconColor:Theme.moduleColour("media","accent",Theme.accent);onClicked:MediaService.toggle()}
            IconButton {icon:"󰒭";implicitWidth:24;implicitHeight:24;enabled:!root.preview&&MediaService.canNext;opacity:enabled?1:.35;iconColor:Theme.moduleColour("media","accent",Theme.accent);onClicked:MediaService.next()}
        }
        Item {
            id:button
            visible:root.kind!=="media"&&root.kind!=="none"
            anchors.left:root.alignRight?undefined:parent.left
            anchors.right:root.alignRight?parent.right:undefined
            height:parent.height;width:Math.min(parent.width,contents.implicitWidth)
            RowLayout {
                id:contents
                layoutDirection:root.alignRight?Qt.RightToLeft:Qt.LeftToRight
                anchors.fill:parent;spacing:6
                Image {visible:root.kind==="chatgpt";source:visible?Quickshell.iconPath("chatgpt"):"";Layout.preferredWidth:15;Layout.preferredHeight:15;sourceSize.width:30;sourceSize.height:30;fillMode:Image.PreserveAspectFit}
                Text {visible:root.kind!=="chatgpt";text:root.glyph;font.family:Theme.fontMono;font.pixelSize:root.iconSize;color:Theme.moduleColour(root.kind,"accent",Theme.accent)}
                Text {Layout.fillWidth:true;Layout.minimumWidth:0;text:root.label;elide:Text.ElideRight;font.family:Theme.fontFamily;font.pixelSize:root.labelSize;font.weight:root.kind==="chatgpt"?Font.DemiBold:Font.Normal;color:Theme.moduleColour(root.kind,"foreground",Theme.text)}
            }
            MouseArea {anchors.fill:parent;cursorShape:Qt.ArrowCursor;onClicked:root.activate()}
        }
    }
}
