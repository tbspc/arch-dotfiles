// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   T A S K S   B L O C K                                                  │
// │   tasks block · the next open tasks                                      │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../../theme"
import "../../../services"
import "../../../components"

// Square (1×2): the count and the next task. Larger: a header with Open, then
// the next tasks by due date, more with each extra row. A row opens the board
// on that task.
Card {
    id: root

    property int cols: 2
    property int rows: 2

    signal panelRequested(string panel)

    readonly property bool square: root.cols === 1
    readonly property int pending: TasksService.pending
    readonly property int late: TasksService.overdue.length

    // Two grid rows hold the header and two tasks; each further row holds two
    // more.
    readonly property int capacity: Math.max(0, root.rows * 2 - 2)

    function openOn(key: string): void {
        TasksService.open(key)
        root.panelRequested("tasks")
    }

    // ── SQUARE ──────────────────────────────────────────────────────────────

    Item { objectName:"design:TasksBlock:1";
        anchors.fill: parent
        visible: root.square

        Text { objectName:"design:TasksBlock:2";
            anchors.left: parent.left
            anchors.top: parent.top
            text: "󰄲"
            font.family: Theme.fontMono
            font.pixelSize: 20
            color: root.late > 0 ? Theme.red : Theme.moduleColour("tasks","accent",Theme.accent)
        }

        Text { objectName:"design:TasksBlock:3";
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 3
            text: "Tasks"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.DemiBold
            color: Theme.moduleColour("tasks","muted",Theme.textMuted)
        }

        Column { objectName:"design:TasksBlock:4";
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0

            Text { objectName:"design:TasksBlock:5";
                text: `${root.pending}`
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeWidget
                font.weight: Font.DemiBold
                color: Theme.moduleColour("tasks","foreground",Theme.text)
            }

            Text { objectName:"design:TasksBlock:6";
                width: parent.width
                text: root.pending === 0
                    ? (TasksService.count === 0 ? "nothing yet" : "all done")
                    : TasksService.summary
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
                color: root.late > 0 ? Theme.red : Theme.moduleColour("tasks","muted",Theme.textMuted)
            }
        }

        HoverHandler { cursorShape: Qt.PointingHandCursor }

        TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: root.openOn("")
        }
    }

    // ── LIST ────────────────────────────────────────────────────────────────

    ColumnLayout { objectName:"design:TasksBlock:7";
        anchors.fill: parent
        visible: !root.square
        spacing: 6

        RowLayout { objectName:"design:TasksBlock:8";
            Layout.fillWidth: true
            spacing: 12

            Rectangle { objectName:"design:TasksBlock:9";
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 10
                color: root.late > 0
                    ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.2)
                    : Qt.rgba(Theme.moduleColour("tasks","accent",Theme.accent).r, Theme.moduleColour("tasks","accent",Theme.accent).g, Theme.moduleColour("tasks","accent",Theme.accent).b, 0.2)

                Text { objectName:"design:TasksBlock:10";
                    anchors.centerIn: parent
                    text: "󰄲"
                    font.family: Theme.fontMono
                    font.pixelSize: 17
                    color: root.late > 0 ? Theme.red : Theme.moduleColour("tasks","accent",Theme.accent)
                }
            }

            ColumnLayout { objectName:"design:TasksBlock:11";
                Layout.fillWidth: true
                spacing: 1

                Text { objectName:"design:TasksBlock:12";
                    text: "Tasks"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.moduleColour("tasks","foreground",Theme.text)
                }

                Text { objectName:"design:TasksBlock:13";
                    Layout.fillWidth: true
                    text: root.pending === 0
                        ? (TasksService.count === 0 ? "No tasks yet" : "All done")
                        : `${root.pending} to do · ${TasksService.summary}`
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLabel
                    color: root.late > 0 ? Theme.red : Theme.moduleColour("tasks","muted",Theme.textMuted)
                }
            }

            PillButton {
                text: "Open"
                implicitHeight: 26
                onClicked: root.openOn("")
            }
        }

        Repeater {
            model: ScriptModel {
                values: TasksService.queue.slice(0, root.capacity)
                objectProp: "key"
            }

            TaskRow {
                required property var modelData

                Layout.fillWidth: true
                task: modelData
                onOpened: root.openOn(modelData.key)
            }
        }

        Item { objectName:"design:TasksBlock:14"; Layout.fillHeight: true }
    }
}
