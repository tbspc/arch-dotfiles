// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C L O C K   M O D U L E                                                │
// │   clock · the island's resting face                                      │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Shapes
import Quickshell

import "../../theme"
import "../../services"
import "../widgets"
import "../../lock"

// The time, optionally with the date. It has no chip or layout slot: it is
// what the island shows at rest.
Item { objectName:"design:ClockModule:1";
    id: root

    // A preview can supply a snapshot without mutating the live island.
    property var configuration: SettingsService
    property bool preview: false
    property bool continuousPlacement:false
    property real spreadLayout:root.configuration.islandLayout==="balanced"?1:0
    property real motionLeftRoom:0
    property real motionRightRoom:0
    property bool dateTravel:false
    readonly property real dateTravelProgress:1-root.layoutProgress
    property bool dateBelow:false
    property string datePosition:root.dateBelow?"bottom":"right"
    readonly property bool verticalDate:root.datePosition==="top"||root.datePosition==="bottom"
    readonly property bool inlineDate:root.datePosition==="left"||root.datePosition==="right"
    property var motionOffsets:({})
    property real layoutProgress:1
    property real leftPadding:root.configuration.islandPaddingLeft
    property real rightPadding:root.configuration.islandPaddingRight
    property real dateFontSize:Theme.fontSizeSmall
    property real dateGap:8
    property string hoverDateFormat:"ddd d MMM"
    property real clockOffsetX:0
    property real clockOffsetY:0
    property real clockScale:1
    property var workspaceMotionOffsets:[]
    property bool workspaceMotionActive:false
    property real dateLift:dateBelow?-8:0
    property real dateOpacity:1
    property real leftVerticalOffset:0
    property real rightVerticalOffset:0

    signal summaryRequested()
    readonly property bool busy: holder.item ? holder.item.busy : false

    implicitWidth: holder.implicitWidth
    implicitHeight: Theme.capsuleHeight

    // Every indicator occupies a fixed-height slot. Scale the contents
    // around that slot's centre so neighbouring icons never move vertically.
    component IndicatorSlot: Item {
        id: slot

        property bool active: false
        property Component sourceComponent
        property real sizeFactor: 1
        property real offset: 0

        implicitWidth: face.item ? face.item.implicitWidth * sizeFactor : 0
        implicitHeight: Theme.capsuleHeight
        width: implicitWidth
        height: implicitHeight
        visible: active
        readonly property string motionRole:objectName.replace(/^island-/,"").replace(/-(left|right)$/,"")
        readonly property real requestedX:slot.offset+(root.motionOffsets[slot.motionRole]?.x||0)
        readonly property real safeX:{
            if(!root.continuousPlacement)return requestedX
            const side=objectName.endsWith("-left")?"left":"right"
            return side==="left"?Math.min(requestedX,root.motionLeftRoom):Math.max(requestedX,-root.motionRightRoom)
        }
        transform:Translate {x:slot.safeX;y:root.motionOffsets[slot.motionRole]?.y||0}

        Loader {
            id: face
            anchors.centerIn: parent
            active: slot.active
            sourceComponent: slot.sourceComponent
            width: item ? item.implicitWidth : 0
            height: item ? item.implicitHeight : 0
            scale: slot.sizeFactor
            transformOrigin: Item.Center
        }

        signal clicked()
        readonly property bool hovered: slot.active && targetHover.hovered
        HoverHandler {
            id: targetHover
            enabled: slot.active
            cursorShape: Qt.ArrowCursor
        }
        MouseArea {
            id: targetArea
            anchors.fill: parent
            z: 10
            enabled: slot.active
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.ArrowCursor
            onClicked: slot.clicked()
        }
    }

    // Tick every second only when seconds are shown.
    SystemClock {
        id: clock
        precision: root.configuration.clockShowsSeconds
            ? SystemClock.Seconds : SystemClock.Minutes
    }

    // Seconds are appended to the chosen format so the two settings stay
    // independent.
    readonly property string format: root.configuration.clockShowsSeconds
        ? root.configuration.clockFormat.replace("mm", "mm:ss")
        : root.configuration.clockFormat

    Loader {
        id: holder
        anchors.fill: parent
        sourceComponent: detail
    }

    Component {
        id: detail

        Item { objectName:"design:ClockModule:2";
            readonly property bool busy: leftGroup.children.some(child => child.hovered === true)
                || rightGroup.children.some(child => child.hovered === true)
            Item { objectName:"design:ClockModule:3";
                id: contents
                anchors.fill: parent

                Binding{target:root;property:"motionLeftRoom";value:Math.max(0,contents.contentLeft-leftGroup.x-leftGroup.width-8);when:root.continuousPlacement}
                Binding{target:root;property:"motionRightRoom";value:Math.max(0,rightGroup.x-contents.contentRight-8);when:root.continuousPlacement}
                readonly property real clockLeft:clockFace.x+clockFace.width*(1-root.clockScale)/2+root.clockOffsetX
                readonly property real clockRight:clockLeft+clockFace.width*root.clockScale
                readonly property real contentLeft:root.dateTravel&&movingDate.visible&&movingDate.opacity>.01?Math.min(clockLeft,movingDate.x):clockLeft
                readonly property real contentRight:root.dateTravel&&movingDate.visible&&movingDate.opacity>.01?Math.max(clockRight,movingDate.x+movingDate.width):clockRight
                readonly property bool centered: root.configuration.islandLayout === "balanced"
                readonly property real leftGap: leftGroup.width > 0 ? 8 : 0
                readonly property real rightGap: rightGroup.width > 0 ? 8 : 0
                readonly property real dateReserve:root.dateTravel&&root.configuration.clockShowsDate?(movingDate.implicitWidth+root.dateGap)*(root.layoutProgress+(root.inlineDate?1-root.layoutProgress:0)):0
                readonly property real visualClockWidth:clockFace.width*root.clockScale
                readonly property real compactX: (contents.width - visualClockWidth-dateReserve
                    - leftGroup.width - rightGroup.width - leftGap - rightGap
                    + root.leftPadding - root.rightPadding) / 2
                readonly property real leftInsetLimit: root.spreadLayout>0
                    ? Math.max(0, clockFace.x - leftGroup.width) : 8
                readonly property real rightInsetLimit: root.spreadLayout>0
                    ? Math.max(0, contents.width - rightGroup.width - clockFace.x - clockFace.width) : 8
                readonly property real leftInset: Math.min(root.leftPadding,
                    leftInsetLimit)
                readonly property real rightInset: Math.min(root.rightPadding,
                    rightInsetLimit)

                Row { objectName:"design:ClockModule:4";
                    id: leftGroup
                    anchors.verticalCenterOffset:root.leftVerticalOffset
                    z: 2
                    x:root.continuousPlacement?Math.min(contents.compactX+(contents.leftInset-contents.compactX)*root.spreadLayout,contents.contentLeft-width-8):contents.compactX+(contents.leftInset-contents.compactX)*root.spreadLayout
                    anchors.verticalCenter:root.continuousPlacement?undefined:parent.verticalCenter
                    y:root.continuousPlacement?(parent.height-height)/2+root.leftVerticalOffset:0
                    width: implicitWidth
                    height: implicitHeight
                    spacing: 8

                    IndicatorSlot {
                        active: !root.configuration.islandChipsEnabled && root.configuration.islandWorkspaces
                            && root.configuration.islandWorkspacesPosition === "left"
                        sourceComponent: workspacePiece
                        offset: root.configuration.islandWorkspacesOffset*root.layoutProgress
                        objectName: "island-workspaces-left"
                        onClicked: ModuleService.togglePanel("overview")
                    }

                    IndicatorSlot {
                        active: !root.configuration.islandChipsEnabled && root.configuration.islandInternet
                            && root.configuration.islandInternetPosition === "left"
                        sourceComponent: internetPiece
                        sizeFactor: root.configuration.islandInternetScale / 100
                        offset: root.configuration.islandInternetOffset*root.layoutProgress
                        objectName: "island-internet-left"
                        onClicked: ModuleService.activate("network")
                    }

                    IndicatorSlot {
                        objectName: "island-bluetooth-left"
                        active: !root.configuration.islandChipsEnabled && root.configuration.islandBluetooth
                            && root.configuration.islandBluetoothPosition === "left"
                        sourceComponent: bluetoothPiece
                        sizeFactor: root.configuration.islandBluetoothScale / 100
                        offset: root.configuration.islandBluetoothOffset
                        onClicked: ModuleService.activate("bluetooth")
                    }

                    IndicatorSlot {
                        objectName: "island-speaker-left"
                        active: !root.configuration.islandChipsEnabled && root.configuration.islandSpeaker
                            && root.configuration.islandSpeakerPosition === "left"
                        sourceComponent: speakerPiece
                        sizeFactor: root.configuration.islandSpeakerScale / 100
                        offset: root.configuration.islandSpeakerOffset
                        onClicked: ModuleService.activate("volume")
                    }

                    IndicatorSlot {
                        active: !root.configuration.islandChipsEnabled && root.configuration.islandBattery && (root.preview || BatteryService.available)
                            && root.configuration.islandBatteryPosition === "left"
                        sourceComponent: batteryPiece
                        sizeFactor: root.configuration.islandBatteryScale / 100
                        offset: root.configuration.islandBatteryOffset*root.layoutProgress
                        objectName: "island-battery-left"
                        onClicked: ModuleService.activate("battery")
                    }
                }

                Row { objectName:"design:ClockModule:5";
                    id: clockFace
                    layoutDirection:root.datePosition==="left"?Qt.RightToLeft:Qt.LeftToRight
                    transform:Scale {origin.x:clockFace.width/2;origin.y:clockFace.height/2;xScale:root.clockScale;yScale:root.clockScale}
                    anchors.verticalCenterOffset:root.dateLift
                    readonly property real dateShift:root.dateTravel?(movingDate.implicitWidth+root.dateGap)/2*(-root.layoutProgress+(root.datePosition==="left"?1:root.datePosition==="right"?-1:0)*(1-root.layoutProgress)):0
                    readonly property real compactClockX:contents.compactX+leftGroup.width+contents.leftGap+(root.dateTravel&&root.datePosition==="left"?contents.dateReserve*(1-root.layoutProgress):0)
                    readonly property real centeredClockX:(contents.width-contents.visualClockWidth)/2+dateShift
                    x:compactClockX+(centeredClockX-compactClockX)*root.spreadLayout-width*(1-root.clockScale)/2+root.clockOffsetX
                    anchors.verticalCenter:root.continuousPlacement?undefined:parent.verticalCenter
                    y:root.continuousPlacement?(parent.height-height)/2+root.dateLift+root.clockOffsetY:root.clockOffsetY
                    width: implicitWidth
                    height: implicitHeight
                    spacing: 0

                    Text { objectName:"design:ClockModule:6";
                        id:clockText
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(clock.date, root.format)
                        font.family: root.configuration.clockFontFamily||Theme.fontFamily
                        font.pixelSize: root.configuration.islandClockSize
                        font.weight: Font.DemiBold
                        color: Theme.moduleColour("clock","foreground",Theme.text)
                    }

                    Item { objectName:"design:ClockModule:7";
                        width: !root.dateTravel&&root.configuration.clockShowsDate&&root.inlineDate ? root.dateGap*root.dateOpacity : 0
                        height: 1
                    }

                    Text { objectName:"design:ClockModule:8";
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !root.dateTravel&&root.configuration.clockShowsDate&&root.inlineDate
                        opacity:root.dateOpacity
                        width:implicitWidth*root.dateOpacity
                        clip:true
                        text: Qt.formatDateTime(clock.date, root.hoverDateFormat)
                        font.family: Theme.fontFamily
                        font.pixelSize:root.dateFontSize
                        color: Theme.moduleColour("date","foreground",Theme.moduleColour("clock","accent",Theme.accent))
                    }
                }

                Text {
                    objectName:"design:ClockModule:hover-date"
                    opacity:root.dateOpacity
                    visible:!root.dateTravel&&root.verticalDate&&root.configuration.clockShowsDate
                    anchors.horizontalCenter:clockFace.horizontalCenter
                    anchors.top:root.datePosition==="bottom"?clockFace.bottom:undefined
                    anchors.bottom:root.datePosition==="top"?clockFace.top:undefined
                    anchors.topMargin:0
                    text:Qt.formatDateTime(clock.date,root.hoverDateFormat)
                    font.family:Theme.fontFamily
                    font.pixelSize:root.dateFontSize
                    color:Theme.moduleColour("date","foreground",Theme.moduleColour("clock","accent",Theme.accent))
                }

                Text {
                    id:movingDate
                    objectName:"design:ClockModule:moving-date"
                    visible:root.dateTravel&&root.configuration.clockShowsDate
                    opacity:root.dateOpacity
                    readonly property point clockOrigin:{const tick=root.clockScale+root.layoutProgress+clockFace.x+clockFace.y;return clockFace.mapToItem(contents,0,0)}
                    readonly property real clockWidth:clockText.width*root.clockScale
                    readonly property real clockHeight:clockText.height*root.clockScale
                    readonly property real inlineX:clockOrigin.x+clockWidth+root.dateGap
                    readonly property real targetX:root.datePosition==="left"?clockOrigin.x-width-root.dateGap:root.datePosition==="right"?inlineX:clockOrigin.x+(clockWidth-width)/2
                    readonly property real inlineY:clockOrigin.y+(clockHeight-height)/2
                    readonly property real targetY:root.datePosition==="top"?clockOrigin.y-height:root.datePosition==="bottom"?clockOrigin.y+clockHeight:inlineY
                    x:inlineX+(targetX-inlineX)*root.dateTravelProgress
                    y:inlineY+(targetY-inlineY)*root.dateTravelProgress
                    text:Qt.formatDateTime(clock.date,root.hoverDateFormat)
                    font.family:Theme.fontFamily;font.pixelSize:root.dateFontSize
                    color:Theme.moduleColour("date","foreground",Theme.moduleColour("clock","accent",Theme.accent))
                }
                Row { objectName:"design:ClockModule:9";
                    id: rightGroup
                    anchors.verticalCenterOffset:root.rightVerticalOffset
                    z: 2
                    readonly property real compactRightX:contents.compactX+leftGroup.width+contents.leftGap+contents.visualClockWidth+contents.dateReserve+contents.rightGap
                    readonly property real naturalX:compactRightX+(contents.width-width-contents.rightInset-compactRightX)*root.spreadLayout
                    x:root.continuousPlacement?Math.max(naturalX,contents.contentRight+8):naturalX
                    anchors.verticalCenter:root.continuousPlacement?undefined:parent.verticalCenter
                    y:root.continuousPlacement?(parent.height-height)/2+root.rightVerticalOffset:0
                    width: implicitWidth
                    height: implicitHeight
                    spacing: 8

                    IndicatorSlot {
                        active: !root.configuration.islandChipsEnabled && root.configuration.islandWorkspaces
                            && root.configuration.islandWorkspacesPosition === "right"
                        sourceComponent: workspacePiece
                        offset: root.configuration.islandWorkspacesOffset*root.layoutProgress
                        objectName: "island-workspaces-right"
                        onClicked: ModuleService.togglePanel("overview")
                    }

                    IndicatorSlot {
                        active: !root.configuration.islandChipsEnabled && root.configuration.islandInternet
                            && root.configuration.islandInternetPosition === "right"
                        sourceComponent: internetPiece
                        sizeFactor: root.configuration.islandInternetScale / 100
                        offset: root.configuration.islandInternetOffset*root.layoutProgress
                        objectName: "island-internet-right"
                        onClicked: ModuleService.activate("network")
                    }

                    IndicatorSlot {
                        objectName: "island-bluetooth-right"
                        active: !root.configuration.islandChipsEnabled && root.configuration.islandBluetooth
                            && root.configuration.islandBluetoothPosition === "right"
                        sourceComponent: bluetoothPiece
                        sizeFactor: root.configuration.islandBluetoothScale / 100
                        offset: root.configuration.islandBluetoothOffset
                        onClicked: ModuleService.activate("bluetooth")
                    }

                    IndicatorSlot {
                        objectName: "island-speaker-right"
                        active: !root.configuration.islandChipsEnabled && root.configuration.islandSpeaker
                            && root.configuration.islandSpeakerPosition === "right"
                        sourceComponent: speakerPiece
                        sizeFactor: root.configuration.islandSpeakerScale / 100
                        offset: root.configuration.islandSpeakerOffset
                        onClicked: ModuleService.activate("volume")
                    }

                    IndicatorSlot {
                        active: !root.configuration.islandChipsEnabled && root.configuration.islandBattery && (root.preview || BatteryService.available)
                            && root.configuration.islandBatteryPosition === "right"
                        sourceComponent: batteryPiece
                        sizeFactor: root.configuration.islandBatteryScale / 100
                        offset: root.configuration.islandBatteryOffset*root.layoutProgress
                        objectName: "island-battery-right"
                        onClicked: ModuleService.activate("battery")
                    }
                }
            }


            MouseArea {
                objectName: "island-clock"
                parent: contents
                x: contents.centered ? (contents.width - clockFace.width) / 2
                    : contents.compactX + leftGroup.width + contents.leftGap
                anchors.verticalCenter: parent.verticalCenter
                width: clockFace.width
                height: Theme.capsuleHeight
                z: 1
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.ArrowCursor
                onClicked: root.summaryRequested()
            }

            Component {
                id: workspacePiece

                Item { objectName:"design:ClockModule:10";
                    id: workspaceSizing
                    readonly property real sizeFactor: root.configuration.islandWorkspacesScale / 100
                    implicitWidth: workspaceWidget.implicitWidth * sizeFactor
                    // Keep the layout slot at the island's height while the
                    // workspace strip grows around its own centre.
                    implicitHeight: Theme.capsuleHeight

                    WorkspacesWidget {
                        id: workspaceWidget
                        anchors.centerIn: parent
                        width: implicitWidth
                        height: Theme.capsuleHeight
                        scale: workspaceSizing.sizeFactor
                        chromeless: true
                        preview: root.preview
                        configuration:root.configuration
                        motionOffsets:root.workspaceMotionOffsets
                        motionActive:root.workspaceMotionActive
                        glowActive: root.configuration.islandWorkspacesGlow
                        style: root.configuration.workspaceStyle
                    }
                }
            }

            Component {
                id: internetPiece

                Item { objectName:"design:ClockModule:11";
                    id: internetIndicator
                    implicitWidth: wifiStyle ? 22 : 18
                    implicitHeight: wifiStyle ? 20 : 12
                    width: implicitWidth
                    height: implicitHeight
                    readonly property int signalLevel: !NetworkService.online ? 0
                        : NetworkService.wifiConnected
                            ? Math.max(1, Math.ceil(NetworkService.strength * 4)) : 4
                    readonly property bool wifiStyle: root.configuration.islandInternetStyle === "wifi"

                    TextMetrics {
                        id: wifiMetrics
                        font: wifiGlyph.font
                        text: wifiGlyph.text
                    }

                    // Use the shell's standard Wi-Fi glyph. Align its ink,
                    // rather than its font line box, to preserve the centre.
                    Text { objectName:"design:ClockModule:12";
                        id: wifiGlyph
                        visible: internetIndicator.wifiStyle
                        text: NetworkService.wifiConnected
                            ? NetworkService.strengthIcon(Math.round(NetworkService.strength * 100))
                            : NetworkService.icon
                        font.family: Theme.fontMono
                        font.pixelSize: 24
                        color: Theme.moduleColour("network","accent",Theme.accent)
                        x: (parent.width - wifiMetrics.tightBoundingRect.width) / 2
                            - wifiMetrics.tightBoundingRect.x
                        y: (parent.height - wifiMetrics.tightBoundingRect.height) / 2
                            - baselineOffset - wifiMetrics.tightBoundingRect.y
                    }

                    Repeater {
                        model: 4
                        visible: !internetIndicator.wifiStyle

                        Rectangle { objectName:"design:ClockModule:13";
                            required property int index
                            visible: !internetIndicator.wifiStyle
                            width: 2.5
                            height: [3, 5, 8, 11][index]
                            x: index * 4
                            y: internetIndicator.height - height
                            radius: 1
                            color: index < internetIndicator.signalLevel
                                ? Theme.moduleColour("network","accent",Theme.accent) : Qt.alpha(Theme.moduleColour("network","accent",Theme.accent), 0.28)
                        }
                    }
                }
            }

            Component {
                id: bluetoothPiece
                Item { objectName:"design:ClockModule:14";
                    implicitWidth: 18
                    implicitHeight: 20
                    TextMetrics {
                        id: bluetoothMetrics
                        font: bluetoothGlyph.font
                        text: bluetoothGlyph.text
                    }
                    Text { objectName:"design:ClockModule:15";
                        id: bluetoothGlyph
                        text: BluetoothService.icon
                        font.family: Theme.fontMono
                        font.pixelSize: 22
                        color: BluetoothService.enabled ? Theme.moduleColour("bluetooth","accent",Theme.accent) : Qt.alpha(Theme.moduleColour("bluetooth","accent",Theme.accent), 0.4)
                        x: (parent.width - bluetoothMetrics.tightBoundingRect.width) / 2
                            - bluetoothMetrics.tightBoundingRect.x
                        y: (parent.height - bluetoothMetrics.tightBoundingRect.height) / 2
                            - baselineOffset - bluetoothMetrics.tightBoundingRect.y
                    }
                }
            }

            Component {
                id: speakerPiece
                Item { objectName:"design:ClockModule:16";
                    implicitWidth: 22 + (root.configuration.islandSpeakerPercent
                        ? 6 + volumeMetrics.advanceWidth("100%") : 0)
                    implicitHeight: 20
                    FontMetrics {
                        id: volumeMetrics
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                    }
                    Item { objectName:"design:ClockModule:17";
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        height: 20
                        TextMetrics {
                            id: speakerMetrics
                            font: speakerGlyph.font
                            text: speakerGlyph.text
                        }
                        Text { objectName:"design:ClockModule:18";
                            id: speakerGlyph
                            text: AudioService.icon
                            font.family: Theme.fontMono
                            font.pixelSize: 22
                            color: AudioService.muted ? Qt.alpha(Theme.moduleColour("volume","accent",Theme.accent), 0.4) : Theme.moduleColour("volume","accent",Theme.accent)
                            x: (parent.width - speakerMetrics.tightBoundingRect.width) / 2
                                - speakerMetrics.tightBoundingRect.x
                            y: (parent.height - speakerMetrics.tightBoundingRect.height) / 2
                                - baselineOffset - speakerMetrics.tightBoundingRect.y
                        }
                    }
                    Text { objectName:"design:ClockModule:19";
                        x: 28
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.configuration.islandSpeakerPercent
                        width: volumeMetrics.advanceWidth("100%")
                        text: `${AudioService.volume}%`
                        font: volumeMetrics.font
                        color: Theme.moduleColour("volume","accent",Theme.accent)
                    }
                }
            }

            Component {
                id: batteryPiece

                IslandBatteryIndicator {configuration:root.configuration; mode: root.configuration.islandBatteryMode }
            }
        }
    }
}
