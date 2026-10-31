// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C   A   L   E   N   D   A   R       M   O   D   U   L   E              │
// │   date · the month when open                                             │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell

import "../../theme"
import "../../services"
import "../../components"

// The date and its month. Days with tasks due get a dot, and the detail lists
// the tasks for the selected day. Finished tasks stay on their day, struck
// through.
Item { objectName:"design:CalendarModule:1";
    id: root

    // Minute precision is enough to catch midnight.
    readonly property SystemClock clock: SystemClock {
        precision: SystemClock.Minutes
    }

    readonly property date today: root.clock.date

    // Weeks start on Monday. Cells outside the month stay blank so every date
    // keeps its weekday column.
    readonly property var cells: {
        const year = root.today.getFullYear()
        const month = root.today.getMonth()
        const shift = (new Date(year, month, 1).getDay() + 6) % 7
        const total = new Date(year, month + 1, 0).getDate()
        const list = []
        for (let blank = 0; blank < shift; blank++)
            list.push(0)
        for (let date = 1; date <= total; date++)
            list.push(date)
        while (list.length % 7 !== 0)
            list.push(0)
        return list
    }

    readonly property var weekdays: ["M", "T", "W", "T", "F", "S", "S"]

    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight

    Loader {
        id: holder
        anchors.fill: parent
        sourceComponent: detail
    }

    Component {
        id: detail

        Item { objectName:"design:CalendarModule:2";
            id: page

            // Selected day: today unless another was clicked; reset whenever
            // the detail is rebuilt.
            property int picked: 0

            readonly property int day: page.picked > 0 ? page.picked : root.today.getDate()
            readonly property bool onToday: page.day === root.today.getDate()

            function keyOf(date: int): string {
                return TasksService.dayKey(
                    new Date(root.today.getFullYear(), root.today.getMonth(), date))
            }

            readonly property var due: TasksService.on(page.keyOf(page.day))

            Column { objectName:"design:CalendarModule:3";
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                Item { objectName:"design:CalendarModule:4";
                    width: parent.width
                    height: 18

                    Text { objectName:"design:CalendarModule:5";
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(root.clock.date, "MMMM yyyy")
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.moduleColour("calendar","foreground",Theme.text)
                    }

                    Text { objectName:"design:CalendarModule:6";
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(root.clock.date, "dddd d")
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.moduleColour("calendar","muted",Theme.textMuted)
                    }
                }

                Grid { objectName:"design:CalendarModule:7";
                    id: month

                    width: parent.width
                    height: 150
                    columns: 7

                    readonly property real cellWidth: width / 7
                    readonly property real cellHeight: height / 7

                    Repeater {
                        model: root.weekdays

                        Item { objectName:"design:CalendarModule:8";
                            required property var modelData

                            width: month.cellWidth
                            height: month.cellHeight

                            Text { objectName:"design:CalendarModule:9";
                                anchors.centerIn: parent
                                text: parent.modelData
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeLabel
                                font.weight: Font.DemiBold
                                color: Theme.moduleColour("calendar","muted",Theme.textMuted)
                            }
                        }
                    }

                    Repeater {
                        model: root.cells

                        Item { objectName:"design:CalendarModule:10";
                            id: cell

                            required property int modelData

                            readonly property bool today:
                                cell.modelData === root.today.getDate()
                            readonly property bool picked:
                                cell.modelData > 0 && cell.modelData === page.day && !cell.today
                            readonly property string key:
                                cell.modelData > 0 ? page.keyOf(cell.modelData) : ""
                            readonly property int tasks: cell.key !== "" ? TasksService.countOn(cell.key) : 0
                            readonly property int pending: cell.key !== "" ? TasksService.pendingOn(cell.key) : 0

                            width: month.cellWidth
                            height: month.cellHeight

                            // Today takes the accent; the selected day gets an
                            // accent ring.
                            Rectangle { objectName:"design:CalendarModule:11";
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) - 2
                                height: width
                                radius: width / 2
                                visible: cell.today || cell.picked
                                color: cell.today ? Theme.moduleColour("calendar","accent",Theme.accent) : "transparent"
                                border.color: Theme.moduleColour("calendar","accent",Theme.accent)
                                border.width: cell.picked ? 1 : 0
                            }

                            Text { objectName:"design:CalendarModule:12";
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: cell.tasks > 0 ? -1 : 0
                                visible: cell.modelData > 0
                                text: `${cell.modelData}`
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeLabel
                                font.weight: cell.today ? Font.DemiBold : Font.Normal
                                color: cell.today ? Theme.accentText : Theme.moduleColour("calendar","foreground",Theme.text)
                            }

                            // Tasks due: accent while any is open, muted once
                            // all are done.
                            Rectangle { objectName:"design:CalendarModule:13";
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                visible: cell.tasks > 0
                                width: 3
                                height: 3
                                radius: 1.5
                                color: cell.today ? Theme.accentText
                                    : (cell.pending > 0 ? Theme.moduleColour("calendar","accent",Theme.accent) : Theme.moduleColour("calendar","muted",Theme.textMuted))
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: cell.modelData > 0
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.picked = cell.today ? 0 : cell.modelData
                            }
                        }
                    }
                }

                Rectangle { objectName:"design:CalendarModule:14";
                    width: parent.width
                    height: 1
                    color: Theme.hairline
                }

                // Tasks due on the selected day: a summary line and up to two
                // rows. Clicking one opens it on the board.
                Column { objectName:"design:CalendarModule:15";
                    width: parent.width
                    spacing: 3

                    Text { objectName:"design:CalendarModule:16";
                        width: parent.width
                        text: {
                            const name = page.onToday ? "Today"
                                : Qt.formatDate(new Date(root.today.getFullYear(),
                                    root.today.getMonth(), page.day), "dddd d")
                            const n = page.due.length
                            const left = page.due.filter(task => task.state !== "done").length
                            if (n === 0)
                                return `${name} · nothing due`
                            return `${name} · ${left} of ${n} to do`
                        }
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLabel
                        font.weight: Font.DemiBold
                        color: Theme.moduleColour("calendar","muted",Theme.textMuted)
                    }

                    Repeater {
                        model: ScriptModel {
                            values: page.due.slice(0, 2)
                            objectProp: "key"
                        }

                        Rectangle { objectName:"design:CalendarModule:17";
                            id: row

                            required property var modelData

                            readonly property bool done: row.modelData.state === "done"

                            width: parent.width
                            height: 18
                            radius: Theme.radiusSmall - 2
                            color: rowMouse.containsMouse ? Theme.surfaceHoverIn(QsWindow.window) : "transparent"

                            Row { objectName:"design:CalendarModule:18";
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 6

                                Text { objectName:"design:CalendarModule:19";
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: TasksService.stateEntry(row.modelData.state).icon
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    color: row.done ? Theme.green : Theme.moduleColour("calendar","accent",Theme.accent)
                                }

                                Text { objectName:"design:CalendarModule:20";
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 17
                                    text: row.modelData.text
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.strikeout: row.done
                                    color: row.done ? Theme.moduleColour("calendar","muted",Theme.textMuted) : Theme.moduleColour("calendar","foreground",Theme.text)
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    TasksService.open(row.modelData.key)
                                    ModuleService.requestPanel("tasks")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
