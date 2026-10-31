// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E S S I O N   P A N E L                                              │
// │   session menu · lock, suspend, log out, reboot, shut down               │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../../theme"
import "../../services"

// The session menu. The same actions (`SessionService.actions`) and the same
// two-press guard as the control centre's power row, in a larger,
// keyboard-first layout: arrows move, Enter commits, and the pointer drives
// the same selection.
FocusScope {
    id: root

    signal closed()

    property int selected: 0
    property string armed: ""

    // Focus on open, or the arrows go to whatever had the keyboard before.
    Component.onCompleted: root.forceActiveFocus()

    readonly property Timer disarm: Timer {
        interval: 3000
        onTriggered: root.armed = ""
    }

    function move(delta: int): void {
        const count = SessionService.actions.length
        root.selected = (root.selected + delta + count) % count
        // Moving away from an armed action disarms it: the confirmation is
        // for that button, not for wherever the cursor ends up next.
        root.armed = ""
    }

    // Destructive actions arm on the first press and run on the second, from
    // the keyboard as from the pointer.
    function activate(action: var): void {
        if (!action)
            return
        if (!action.destructive || root.armed === action.id) {
            root.armed = ""
            root.disarm.stop()
            // Dismiss the menu; the lock request itself never waits for it.
            root.closed()
            SessionService.run(action.id)
            return
        }
        root.armed = action.id
        root.disarm.restart()
    }

    Keys.onLeftPressed: root.move(-1)
    Keys.onRightPressed: root.move(1)
    Keys.onReturnPressed: root.activate(SessionService.actions[root.selected])
    Keys.onEnterPressed: root.activate(SessionService.actions[root.selected])

    ColumnLayout { objectName:"design:SessionPanel:1";
        anchors.fill: parent
        spacing: 18

        // The confirmation is shown on the tile itself: red, reading
        // "Confirm".
        RowLayout { objectName:"design:SessionPanel:2";
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Repeater {
                model: SessionService.actions

                Rectangle { objectName:"design:SessionPanel:3";
                    id: tile

                    required property var modelData
                    required property int index

                    readonly property bool isSelected: root.selected === tile.index
                    readonly property bool isArmed: root.armed === tile.modelData.id

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusLarge

                    // Armed is red, selected is the accent. Only the selected
                    // tile can be armed, so they never conflict.
                    color: {
                        if (tile.isArmed)
                            return Theme.red
                        return tile.isSelected ? Theme.surfaceHoverIn(QsWindow.window) : Theme.surfaceIn(QsWindow.window)
                    }
                    border.color: {
                        if (tile.isArmed)
                            return Theme.red
                        return tile.isSelected ? Theme.moduleColour("session","accent",Theme.accent) : Theme.borderIn(QsWindow.window)
                    }
                    border.width: tile.isSelected || tile.isArmed ? 2 : 1

                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

                    Column { objectName:"design:SessionPanel:4";
                        anchors.centerIn: parent
                        spacing: 10

                        Text { objectName:"design:SessionPanel:5";
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.icon
                            font.family: Theme.fontMono
                            font.pixelSize: 30
                            color: {
                                if (tile.isArmed)
                                    return Theme.accentText
                                return tile.isSelected ? Theme.moduleColour("session","accent",Theme.accent) : Theme.moduleColour("session","foreground",Theme.text)
                            }

                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                        }

                        Text { objectName:"design:SessionPanel:6";
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.isArmed ? "Confirm" : tile.modelData.label
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: tile.isSelected ? Font.DemiBold : Font.Normal
                            color: tile.isArmed ? Theme.accentText : Theme.moduleColour("session","muted",Theme.textMuted)

                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                        }
                    }

                    // The pointer drives the same selection as the arrows.
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                onEntered:if(tile.modelData.id==="lock")LockService.prefetchDesktop()
                onPressed:if(tile.modelData.id==="lock")LockService.prefetchDesktop()
                        onPositionChanged: root.selected = tile.index
                        onClicked: {
                            root.selected = tile.index
                            root.activate(tile.modelData)
                        }
                    }
                }
            }
        }
    }
}
