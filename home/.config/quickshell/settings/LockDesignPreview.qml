import QtQuick
import QtQuick.Effects
import Quickshell
import "../theme"
import "../services"
import "../lock"
import "../lock/common"

Rectangle {
    id: root
    objectName: "lock-design-preview"
    property var configuration:LockStyleService.values
    property bool interactive:true
    property bool showGuides: true
    property string mode: "idle"
    property string selected: "clock"
    property int referenceWidth: Quickshell.screens[0]?.width || 1920
    property int referenceHeight: Quickshell.screens[0]?.height || 1080
    readonly property real fit: width / referenceWidth
    implicitHeight: width * referenceHeight / referenceWidth
    radius: Theme.radiusMedium
    color: Theme.background
    clip: true

    Item {
        id: canvas
        width: root.referenceWidth
        height: root.referenceHeight
        scale: root.fit
        transformOrigin: Item.TopLeft
        Image {
            id: wallpaper
            anchors.fill: parent
            source:root.configuration.lockBackdrop==="desktop"&&LockService.shotReady?LockService.desktopSource(Quickshell.screens[0]?.name||""):WallpaperService.currentWallpaper
            fillMode: Image.PreserveAspectCrop
            visible: false
            asynchronous: true
            cache: true
        }
        MultiEffect {
            anchors.fill: parent
            source: wallpaper
            autoPaddingEnabled:false
            blurEnabled:radiusWanted>0
            blur: 1
            readonly property real radiusWanted:root.configuration.lockBlur * (0.4 + (root.mode === "idle" ? 0 : root.configuration.lockExtraBlur / 100))
            blurMax:Math.max(1,Math.min(64,radiusWanted))
            blurMultiplier:Math.max(1,radiusWanted/64)
            brightness: -0.05 * root.configuration.lockDim / 18
            saturation:(root.configuration.lockVibrance??42)/100
        }
        Rectangle { anchors.fill: parent; color: Theme.scrim; opacity: root.configuration.lockDim / 100 }
        ReferenceStatus {
            visible:root.configuration.lockStatus&&root.configuration.lockDesign==="reference"
            anchors.right:parent.right;anchors.rightMargin:26;y:20;width:implicitWidth;height:implicitHeight
            percent:BatteryService.available?BatteryService.percent:80;ink:root.configuration.lockTextColor;opacity:.8
        }
        Row {
            visible: root.configuration.lockStatus&&root.configuration.lockDesign!=="reference"
            anchors.right: parent.right
            anchors.rightMargin: 28
            y: 18
            spacing: 12
            Text {
                text: BatteryService.available ? BatteryService.icon + " " + BatteryService.percent + "%" : "80%"
                font.family: Theme.fontMono
                font.pixelSize: 13
                color: root.configuration.lockTextColor
            }
            Text { text: NetworkService.icon; font.family: Theme.fontMono; font.pixelSize: 15; color: root.configuration.lockTextColor }
        }
        LockIslandTransition {
            anchors.fill: parent
            visible:root.configuration.lockIslandEnabled&&root.configuration.lockDesign!=="reference"
            preview: true
            held: 1
            previewLeaving: false
        }
        LockClock {
            objectName: "lock-design-clock"
            configuration:root.configuration
            id: clockFace
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.configuration.lockClockTop
            style: root.configuration.lockClock
            width: implicitWidth
            height: implicitHeight
            Rectangle {
                anchors.fill: parent
                anchors.margins: -10
                radius: 12
                color: "transparent"
                border.color: Theme.accentIn(QsWindow.window)
                border.width: 2 / root.fit
                opacity: root.showGuides && root.selected === "clock" ? 0.65 : 0
            }
            MouseArea {
                enabled:root.interactive
                anchors.fill: parent
                anchors.margins: -12
                cursorShape: Qt.SizeVerCursor
                property real startY: 0
                property real startTop: 0
                onPressed: mouse => {
                    root.selected = "clock"
                    startY = mapToItem(root, mouse.x, mouse.y).y
                    startTop = root.configuration.lockClockTop
                }
                onPositionChanged: mouse => {
                    if (!pressed) return
                    const delta = (mapToItem(root, mouse.x, mouse.y).y - startY) / root.fit
                    SettingsService.set("lockClockTop", Math.round(Math.max(0, Math.min(320, startTop + delta))))
                }
            }
        }
        LockAccount {
            objectName: "lock-design-profile"
            configuration:root.configuration
            id: profile
            glassSource:wallpaper
            preview: true
            previewAwake: root.mode !== "idle"
            previewFailed: root.mode === "error"
            previewCaps: root.mode === "caps"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.configuration.lockAccountBottom
            width: implicitWidth
            height: implicitHeight
            Rectangle {
                anchors.fill: parent
                anchors.margins: -10
                radius: 12
                color: "transparent"
                border.color: Theme.accentIn(QsWindow.window)
                border.width: 2 / root.fit
                opacity: root.showGuides && (root.selected === "profile" || root.selected === "field") ? 0.65 : 0
            }
            MouseArea {
                enabled:root.interactive
                anchors.fill: parent
                anchors.margins: -12
                cursorShape: Qt.SizeVerCursor
                property real startY: 0
                property real startBottom: 0
                property bool moving: false
                onPressed: mouse => {
                    root.selected = mouse.y >= profile.promptY ? "field" : "profile"
                    moving = root.selected === "profile"
                    startY = mapToItem(root, mouse.x, mouse.y).y
                    startBottom = root.configuration.lockAccountBottom
                }
                onPositionChanged: mouse => {
                    if (!pressed || !moving) return
                    const delta = (mapToItem(root, mouse.x, mouse.y).y - startY) / root.fit
                    SettingsService.set("lockAccountBottom", Math.round(Math.max(0, Math.min(360, startBottom - delta))))
                }
            }
        }
    }
}
