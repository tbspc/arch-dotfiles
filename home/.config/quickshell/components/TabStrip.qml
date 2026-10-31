// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   T A B   S T R I P                                                      │
// │   tabs within a settings page                                            │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../theme"
import "../services"

// Pills naming the parts of a settings page, all visible, the current one
// filled. A page with a single part gets no strip.
Item { objectName:"design:TabStrip:1";
    id: root

    // Entries of { id, label }.
    property var tabs: []
    property string current: ""
    readonly property bool modern: Theme.modernIn(QsWindow.window)
    property int selectionRevision: 0
    readonly property Item selectedTab: {const revision = root.selectionRevision; return tabItems.count ? tabItems.itemAt(root.tabs.findIndex(t => t.id === root.current)) : null }

    signal picked(string id)

    Layout.fillWidth: true
    implicitHeight: root.tabs.length > 1 ? tabFlow.implicitHeight + 4 : 0
    visible: root.tabs.length > 1

    Rectangle {
        visible: root.modern && root.selectedTab !== null
        x: tabFlow.x + (root.selectedTab ? root.selectedTab.x : 0)
        y: tabFlow.y + (root.selectedTab ? root.selectedTab.y : 0)
        width: root.selectedTab ? root.selectedTab.width : 0
        height: root.selectedTab ? root.selectedTab.height : 0
        radius: 8; color: Theme.colourIn(QsWindow.window,"cardBackground","#fefdfb")
        border.width: 1; border.color: Theme.borderIn(QsWindow.window)
        Behavior on x { enabled: root.modern && root.visible; SpringAnimation { spring: 5; damping: .42; epsilon: .1 } }
        Behavior on y { enabled: root.modern && root.visible; SpringAnimation { spring: 5; damping: .42; epsilon: .1 } }
        Behavior on width { enabled: root.modern && root.visible; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Flow { objectName:"design:TabStrip:2";
        id:tabFlow
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 4

        Repeater {
            id: tabItems
            onItemAdded: root.selectionRevision++
            onItemRemoved: root.selectionRevision++
            model: root.tabs

            Rectangle { objectName:"design:TabStrip:3";
                id: pill

                required property var modelData

                readonly property bool active: pill.modelData.id === root.current

                width: caption.implicitWidth + 24
                height: Theme.controlSizeIn(QsWindow.window, 26)
                radius:Theme.radiusIn(QsWindow.window,"tabRadius",height/2)
                color: root.modern ? (pill.active ? "transparent" : pillMouse.containsMouse ? Theme.surfaceHoverIn(QsWindow.window) : "transparent") : pill.active ? (SettingsDesignService.style.navigation === "studio" ? Qt.alpha(Theme.accentIn(QsWindow.window), .11) : Theme.accentIn(QsWindow.window))
                    : (pillMouse.containsMouse ? Theme.surfaceHoverIn(QsWindow.window) : Theme.surfaceIn(QsWindow.window))
                border.color: pill.active ? Theme.accentIn(QsWindow.window) : Theme.borderIn(QsWindow.window)
                border.width: root.modern ? 0 : 1

                Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

                Text { objectName:"design:TabStrip:4";
                    id: caption

                    anchors.centerIn: parent
                    text: pill.modelData.label
                    font.family: Theme.fontIn(QsWindow.window)
                    font.pixelSize: Theme.textSizeIn(QsWindow.window, Theme.fontSizeSmall)
                    font.weight: pill.active ? Font.DemiBold : Font.Normal
                    color: root.modern ? (pill.active ? Theme.textIn(QsWindow.window) : Theme.mutedIn(QsWindow.window)) : pill.active ? (SettingsDesignService.style.navigation === "studio" ? Theme.accentIn(QsWindow.window) : Theme.accentTextIn(QsWindow.window)) : Theme.mutedIn(QsWindow.window)

                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                }

                MouseArea {
                    id: pillMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(pill.modelData.id)
                }
            }
        }
    }
}
