// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   T A S K S   M O D U L E                                                │
// │   tasks · open count and the next few                                    │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../theme"
import "../../services"
import "../../components"

// The next three tasks by due date with their ticks, plus New and Open. A row
// opens the board on that task; editing happens in the panel.
Item { objectName:"design:TasksModule:1";
    id: root

    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight

    readonly property int pending: TasksService.pending
    readonly property int late: TasksService.overdue.length

    Loader {
        id: holder
        anchors.fill: parent
        sourceComponent: detail
    }

    function openOn(key: string): void {
        TasksService.open(key)
        ModuleService.requestPanel("tasks")
    }

    Component {
        id: detail

        ModuleCard {
            title: "Tasks"
            subtitle: root.pending === 0
                ? (TasksService.count === 0 ? "No tasks yet" : "All done")
                : TasksService.summary
            // The count to do, in red while any is late.
            figure: root.pending > 0 ? `${root.pending}` : ""
            figureColor: root.late > 0 ? Theme.red : Theme.moduleColour("tasks","foreground",Theme.text)

            mark: RingIndicator {
                anchors.fill: parent
                thickness: 3
                progress: 0
                trackColor: Theme.indicatorDim

                Text { objectName:"design:TasksModule:2";
                    anchors.centerIn: parent
                    text: "󰄲"
                    font.family: Theme.fontMono
                    font.pixelSize: 20
                    color: root.late > 0 ? Theme.red : Theme.moduleColour("tasks","accent",Theme.indicator)
                }
            }

            // Soonest first. The tick completes a task in place; the rest of
            // the row opens it.
            Repeater {
                model: ScriptModel {
                    values: TasksService.queue.slice(0, 3)
                    objectProp: "key"
                }

                TaskRow {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.cardRow
                    task: modelData
                    onOpened: root.openOn(modelData.key)
                }
            }

            RowLayout { objectName:"design:TasksModule:3";
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.cardRow
                spacing: 8

                Item { objectName:"design:TasksModule:4"; Layout.fillWidth: true }

                PillButton {
                    implicitHeight: Theme.cardRow
                    text: "New"
                    icon: "󰐕"
                    onClicked: {
                        TasksService.create()
                        ModuleService.requestPanel("tasks")
                    }
                }

                PillButton {
                    implicitHeight: Theme.cardRow
                    text: "Open"
                    icon: "󰄲"
                    onClicked: root.openOn("")
                }
            }
        }
    }
}
