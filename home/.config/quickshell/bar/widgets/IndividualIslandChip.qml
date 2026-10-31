import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell.Widgets
import "../../theme"
import "../../services"
import "../../components"
import "../modules"

Item {
    id: root
    objectName:"design:chip"
    property var barConfiguration:SettingsService
    property string chipId: "internet"
    property var configuration: IslandChipService.get(chipId)
    signal activated()
    property bool preview: false
    implicitWidth: configuration.width
    implicitHeight: configuration.height
    readonly property real iconSize: Math.min(width - 8, height - 8) * configuration.iconScale / 100
    readonly property string glyph: chipId === "internet" ? NetworkService.icon
        : chipId === "bluetooth" ? BluetoothService.icon : chipId === "speaker" ? AudioService.icon : "󰎈"
    readonly property string value: chipId === "speaker" ? `${AudioService.volume}%`
        : chipId === "internet" ? NetworkService.ssid || "Network" : MediaService.title || "No media"
    readonly property bool wide: configuration.display === "title" || configuration.display === "controls" || configuration.display === "value"

    Rectangle {
        id: body
        antialiasing:true
        border.pixelAligned:false
        anchors.fill: parent
        radius: root.configuration.style === "rounded" ? 10 : Math.min(width,height) / 2
        color: SettingsService.shellColours[root.chipId]?.background ? Theme.moduleColour(root.chipId,"background",Theme.islandGround) : Theme.surfaceStyle==="tahoe" && root.configuration.surface!=="outline" ? Theme.islandGround : root.configuration.surface === "outline" ? "transparent"
            : root.configuration.surface === "glass" ? Qt.rgba(1,1,1,0.14)
            : root.configuration.surface === "theme" ? Theme.islandGround : "#080a0c"
        border.color: Theme.surfaceStyle==="tahoe" && root.configuration.surface!=="outline" ? Theme.islandGround : root.configuration.surface === "outline" ? Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"accent",Theme.accent) : Qt.alpha(Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"foreground",Theme.text),0.18)
        border.width: 1
        // Only artwork needs an offscreen clipping texture. Ordinary icons
        // and rings stay as vector geometry at the final screen scale.
        Loader {
            anchors.fill:parent
            active:root.chipId==="media" && root.configuration.display==="artwork" && !!MediaService.artUrl
            sourceComponent:ClippingRectangle {
                radius:body.radius;color:"transparent";antialiasing:true
                contentUnderBorder:true
                Image {anchors.fill:parent;source:MediaService.artUrl;fillMode:Image.PreserveAspectCrop;asynchronous:true;cache:true;smooth:true;mipmap:true}
            }
        }
        Text {
            anchors.centerIn: parent
            visible: root.chipId !== "battery" && root.chipId !== "workspaces"
                && !(root.chipId === "media" && root.configuration.display === "artwork" && MediaService.artUrl)
                && !root.wide
            text: root.glyph
            font.family: Theme.fontMono
            font.pixelSize: root.iconSize * 0.72
            color: Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"accent",Theme.accent)
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            visible: ["internet","speaker"].includes(root.chipId) && root.configuration.display === "ring"
            color: "transparent"
            radius: Math.min(width,height)/2
            antialiasing:true
            border.pixelAligned:false
            border.width: 1.5
            border.color: root.chipId === "speaker" ? (AudioService.muted ? Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"muted",Theme.textMuted) : Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"accent",Theme.accent)) : NetworkService.online ? Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"accent",Theme.accent) : Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"muted",Theme.textMuted)
        }
        IslandBatteryIndicator {
            configuration:root.barConfiguration
            anchors.centerIn: parent
            visible: root.chipId === "battery" && root.configuration.display !== "ring"
            width: implicitWidth
            height: implicitHeight
            mode: root.configuration.display === "both" ? "both" : root.configuration.display === "percent" ? "percent" : "icon"
            scale: Math.min((root.width - 8) / Math.max(1,width), (root.height - 8) / Math.max(1,height)) * root.configuration.iconScale / 100
        }
        RingIndicator {
            id:batteryRing
            anchors.fill:parent;anchors.margins:3.5
            visible:root.chipId==="battery" && root.configuration.display==="ring"
            property color hue:Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"accent",Theme.accent)
            progress:BatteryService.percent/100;thickness:2
            fillColor:hue;trackColor:Qt.alpha(hue,.2)
            layer.enabled:visible && (root.barConfiguration.islandBatteryGlow??false)
            layer.effect:MultiEffect {shadowEnabled:true;shadowColor:batteryRing.hue;shadowOpacity:.65;shadowBlur:.5;blurMax:32;shadowHorizontalOffset:0;shadowVerticalOffset:0;autoPaddingEnabled:true}
        }
        Item {
            anchors.centerIn: parent
            visible: batteryRing.visible
            width: 9; height: 14
            scale: root.configuration.iconScale/100
            Rectangle { x:3; y:0; width:3; height:2; radius:1; color:Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"accent",Theme.accent) }
            Rectangle {
                x:1; y:2; width:7; height:11; radius:1.5
                color: BatteryService.pluggedIn ? Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"accent",Theme.accent) : "transparent"
                border.color:Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"accent",Theme.accent); border.width:1
                Rectangle {
                    visible: !BatteryService.pluggedIn
                    x:1; width:5; height:9*Math.max(0,Math.min(1,BatteryService.percent/100)); y:10-height
                    radius:0.5; color:Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"accent",Theme.accent)
                }
                Text {
                    anchors.centerIn: parent
                    visible: BatteryService.pluggedIn
                    text:"ϟ"; font.pixelSize:11; font.bold:true; color:Theme.accentText
                }
            }
        }
        WorkspacesWidget {
            configuration:root.barConfiguration
            style:root.barConfiguration.workspaceStyle??SettingsService.workspaceStyle
            anchors.centerIn: parent
            visible: root.chipId === "workspaces"
            width: implicitWidth
            height: Theme.capsuleHeight
            chromeless: true
            preview: root.preview
            glowActive:root.barConfiguration.islandWorkspacesGlow??false
            scale: Math.min((root.width-12)/Math.max(1,implicitWidth), (root.height-6)/Math.max(1,height)) * root.configuration.iconScale/100
        }
        Row {
            anchors.centerIn: parent
            visible: root.wide && root.chipId !== "battery" && root.chipId !== "workspaces"
            spacing: 7
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.glyph
                font.family: Theme.fontMono
                font.pixelSize: Math.min(22,root.iconSize * 0.7)
                color: Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"accent",Theme.accent)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.configuration.display !== "controls"
                text: root.value
                width: Math.max(16,root.width-48)
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall * root.configuration.iconScale/100
                color: Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"foreground",Theme.text)
            }
            Repeater {
                model: root.chipId === "media" && root.configuration.display === "controls" ? ["󰒮",MediaService.playing ? "󰏤" : "󰐊","󰒭"] : []
                Text {
                    required property string modelData
                    required property int index
                    readonly property string mediaAction:["previous","play","next"][index]
                    readonly property var controlStyle:root.configuration.controls?.[mediaAction]||({})
                    objectName:"design:media-control-"+mediaAction
                    transform:[Translate{x:controlStyle.x??0;y:controlStyle.y??0},Scale{xScale:(controlStyle.scale??100)/100;yScale:xScale;origin.x:0;origin.y:0}]
                    text: modelData
                    font.family: Theme.fontMono
                    font.pixelSize: Math.min(24,root.iconSize * 0.8)
                    color: Theme.moduleColour(root.chipId==="internet"?"network":root.chipId==="speaker"?"volume":root.chipId,"foreground",Theme.text)
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.preview
                        cursorShape: Qt.ArrowCursor
                        onClicked: { if (index === 0) MediaService.previous(); else if (index === 2) MediaService.next(); else MediaService.toggle() }
                    }
                }
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: !root.preview
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.ArrowCursor
        onClicked: mouse => {
            if (root.chipId === "media" && mouse.button === Qt.RightButton) MediaService.toggle()
            else root.activated()
        }
    }
}
