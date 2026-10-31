import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import "../../theme"
import "../../services"

Item { objectName:"design:IslandBatteryIndicator:1";
    id: root
    layer.enabled:root.configuration.islandBatteryGlow??false
    layer.effect:MultiEffect {
        shadowEnabled:true
        shadowColor:Theme.moduleColour("battery","accent",Theme.accent)
        shadowOpacity:.65;shadowBlur:.5;blurMax:32
        shadowHorizontalOffset:0;shadowVerticalOffset:0
        autoPaddingEnabled:true
    }
    property var configuration:SettingsService
    property string mode: "both"
    property string iconStyle: root.configuration.islandBatteryIconStyle || "new"
    readonly property bool modern: mode === "both" || (mode === "icon" && iconStyle === "new")
    readonly property real charge: Math.max(0,Math.min(1,BatteryService.percent/100))
    implicitWidth: mode === "percent" ? percent.implicitWidth : iconStyle==="reference"?reference.implicitWidth:38
    implicitHeight: mode === "percent" ? percent.implicitHeight : iconStyle==="reference"?26:18

    ReferenceBattery {id:reference;anchors.centerIn:parent;visible:root.iconStyle==="reference"&&root.mode!=="percent";width:implicitWidth;height:implicitHeight;percentage:root.mode==="both";ink:Theme.moduleColour("battery","accent",Theme.accent);boltInk:Theme.accentText;fillOpacity:(root.configuration.islandBatteryFillOpacity??100)/100;emptyOpacity:(root.configuration.islandBatteryEmptyOpacity??24)/100;tipOpacity:(root.configuration.islandBatteryTipOpacity??32)/100;charge:root.charge;charging:BatteryService.pluggedIn;percentageText:BatteryService.percent+"%";textFont:Theme.fontFamily;textSize:Theme.fontSizeSmall;textColour:Theme.moduleColour("battery","foreground",Theme.accent)}
    component Bolt: Shape {
        id: bolt
        property color ink: Theme.accentText
        width: 6; height: 9
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: 0; strokeColor: "transparent"; fillColor: bolt.ink
            startX:3.8; startY:0
            PathLine {x:0;y:5}
            PathLine {x:2.6;y:5}
            PathLine {x:1.8;y:9}
            PathLine {x:6;y:3.5}
            PathLine {x:3.5;y:3.5}
            PathLine {x:3.8;y:0}
        }
    }
    component Readout: Row {
        property color ink: Theme.moduleColour("battery","accent",Theme.accent)
        height: 16
        spacing: 2
        Text { objectName:"design:IslandBatteryIndicator:2";
            text: `${BatteryService.percent}`
            height: 16
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Bold
            color: parent.ink
        }
        Bolt { anchors.verticalCenter: parent.verticalCenter; visible: BatteryService.pluggedIn; ink: parent.ink }
    }
    Item { objectName:"design:IslandBatteryIndicator:3";
        anchors.centerIn: parent
        visible: root.mode !== "percent" && root.iconStyle!=="reference"
        width: 38; height: 18
        Rectangle { objectName:"design:IslandBatteryIndicator:4";
            id: body
            x:0; y:1; width:33; height:16; radius:5
            color: root.modern ? Qt.alpha(Theme.moduleColour("battery","accent",Theme.accent),0.18) : "transparent"
            border.color: Theme.moduleColour("battery","accent",Theme.accent); border.width:1
            Rectangle { objectName:"design:IslandBatteryIndicator:5";
                id: fill
                visible: root.modern
                width: parent.width*root.charge; height:parent.height
                radius:parent.radius; color:Theme.moduleColour("battery","accent",Theme.accent)
                Behavior on width { NumberAnimation {duration:Theme.durationMedium;easing.type:Easing.OutCubic} }
            }
            Rectangle { objectName:"design:IslandBatteryIndicator:6";
                visible: !root.modern
                x:2;y:3;width:29;height:10;radius:3;color:Qt.alpha(Theme.moduleColour("battery","accent",Theme.accent),0.18)
                Rectangle { objectName:"design:IslandBatteryIndicator:7";width:parent.width*root.charge;height:parent.height;radius:parent.radius;color:Theme.moduleColour("battery","accent",Theme.accent)}
            }
            Readout { anchors.centerIn: parent; visible:root.mode === "both"; ink:Theme.moduleColour("battery","accent",Theme.accent) }
            Item { objectName:"design:IslandBatteryIndicator:8";
                width:fill.width;height:body.height;clip:true
                visible:root.mode === "both"
                Item { objectName:"design:IslandBatteryIndicator:9";
                    width:body.width;height:body.height
                    Readout { anchors.centerIn:parent;ink:Theme.accentText }
                }
            }
            Bolt {
                anchors.centerIn:parent
                visible:root.mode === "icon" && BatteryService.pluggedIn
                ink:root.modern && root.charge >= 0.5 ? Theme.accentText : Theme.moduleColour("battery","accent",Theme.accent)
            }
        }
        Rectangle { objectName:"design:IslandBatteryIndicator:10"; x:33;y:6;width:3;height:6;radius:2;color:Theme.moduleColour("battery","accent",Theme.accent) }
    }
    Text { objectName:"design:IslandBatteryIndicator:11";
        id:percent
        anchors.centerIn:parent
        visible:root.mode === "percent"
        text:`${BatteryService.percent}%`
        font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSmall;font.weight:Font.DemiBold;color:Theme.moduleColour("battery","accent",Theme.accent)
    }
}
