// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   B O A R D   P A N E L                                                  │
// │   task board · three lanes and the task editor                           │
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

// Simple reminders and the existing editable task sheet; no Kanban board.
FocusScope {
    id: root

    signal closed()

    readonly property string opened: TasksService.opened
    readonly property var task: TasksService.entry(root.opened)

    readonly property int gap: 12

    // Laid out at the declared size from the first frame, whatever size the
    // island is animating through.
    readonly property int roomWidth: TasksService.panelWidth - 2 * Theme.panelPadding
    readonly property int roomHeight: TasksService.panelHeight - 2 * Theme.panelPadding

    Component.onCompleted: root.forceActiveFocus()
    Component.onDestruction: TasksService.leave()

    // Escape returns to the board when the task was opened there, and closes
    // the island when it came from the calendar.
    Keys.onEscapePressed: event => {
        if (root.opened === "" || TasksService.direct) {
            event.accepted = false
            return
        }
        TasksService.leave()
    }

    function back(): void {
        if (TasksService.direct)
            root.closed()
        else
            TasksService.leave()
    }

    Loader {
        focus: true
        sourceComponent: root.opened === "" ? board : editor
    }

    // Ordinary reminders remain available after retiring the Kanban board.
    Component {
        id: board
        ColumnLayout {
            width:root.roomWidth;height:root.roomHeight;spacing:12
            RowLayout {
                Layout.fillWidth:true
                Text{text:"Tasks";font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeLarge;font.weight:Font.DemiBold;color:Theme.moduleColour("tasks","foreground",Theme.text)}
                Item{Layout.fillWidth:true}
                PillButton{text:"New task";icon:"󰐕";onClicked:TasksService.create(true)}
            }
            ListView {
                Layout.fillWidth:true;Layout.fillHeight:true;clip:true;spacing:6
                model:ScriptModel{values:TasksService.tasks.slice().sort((a,b)=>a.created-b.created);objectProp:"key"}
                delegate:TaskRow {
                    required property var modelData
                    width:ListView.view.width;height:Theme.cardRow;task:modelData
                    onOpened:TasksService.open(modelData.key,true)
                }
            }
            Text{visible:TasksService.tasks.length===0;text:"No tasks yet";color:Theme.moduleColour("tasks","muted",Theme.textMuted);font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeRegular}
        }
    }

    // ── TASK ────────────────────────────────────────────────────────────────

    Component {
        id: editor

        Item { objectName:"design:TasksPanel:29";
            id: sheet

            width: root.roomWidth
            height: root.roomHeight

            readonly property string key: root.opened
            readonly property string due: root.task ? root.task.due : ""

            // Whether the month is open over the day's button.
            property bool picking: false

            // Read from the service, not `root.task`: this runs inside the
            // change that built the sheet, before the binding re-evaluates.
            // A new task focuses its line.
            Component.onCompleted: {
                const task = TasksService.entry(root.opened)
                line.text = task ? task.text : ""
                more.text = task ? (task.body ?? "") : ""
                line.cursorPosition = line.length
                line.forceActiveFocus()
            }

            function pick(day: string): void {
                TasksService.setDue(sheet.key, day)
                sheet.picking = false
                line.forceActiveFocus()
            }

            ColumnLayout { objectName:"design:TasksPanel:30";
                anchors.fill: parent
                spacing: 12

                // The line, and when it was added beside it.
                RowLayout { objectName:"design:TasksPanel:31";
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 12

                    TextInput { objectName:"design:TasksPanel:32";
                        id: line

                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.DemiBold
                        color: Theme.moduleColour("tasks","foreground",Theme.text)
                        clip: true
                        selectByMouse: true
                        selectionColor: Theme.moduleColour("tasks","accent",Theme.accent)
                        selectedTextColor: Theme.accentText

                        onTextEdited: TasksService.update(sheet.key, { text: line.text.trim() })
                        // Enter moves on to the notes.
                        Keys.onReturnPressed: more.forceActiveFocus()
                        Keys.onEnterPressed: more.forceActiveFocus()

                        Text { objectName:"design:TasksPanel:33";
                            anchors.verticalCenter: parent.verticalCenter
                            visible: line.text === ""
                            text: "What has to be done"
                            font: line.font
                            color: Theme.moduleColour("tasks","muted",Theme.textMuted)
                        }
                    }

                    Text { objectName:"design:TasksPanel:34";
                        text: {
                            if (!root.task)
                                return ""
                            const finished = root.task.state === "done" && root.task.finished > 0
                            const age = NotesService.ageOf(finished ? root.task.finished : root.task.created)
                            return `${finished ? "done" : "added"} ${age === "just now" ? age : age + " ago"}`
                        }
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeLabel
                        color: Theme.moduleColour("tasks","muted",Theme.textMuted)
                    }
                }

                Rectangle { objectName:"design:TasksPanel:35";
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.borderIn(QsWindow.window)
                }

                // The task's notes.
                Flickable { objectName:"design:TasksPanel:36";
                    id: scroller

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: more.contentHeight + 8
                    boundsBehavior: Flickable.StopAtBounds

                    function follow(rectangle: rect): void {
                        if (rectangle.y < scroller.contentY)
                            scroller.contentY = rectangle.y
                        else if (rectangle.y + rectangle.height > scroller.contentY + scroller.height)
                            scroller.contentY = rectangle.y + rectangle.height - scroller.height
                    }

                    TextEdit { objectName:"design:TasksPanel:37";
                        id: more

                        width: scroller.width
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeRegular
                        color: Theme.moduleColour("tasks","foreground",Theme.text)
                        selectByMouse: true
                        selectionColor: Theme.moduleColour("tasks","accent",Theme.accent)
                        selectedTextColor: Theme.accentText

                        onTextChanged: {
                            if (root.task && more.text !== (root.task.body ?? ""))
                                TasksService.update(sheet.key, { body: more.text })
                        }
                        onCursorRectangleChanged: scroller.follow(more.cursorRectangle)

                        Text { objectName:"design:TasksPanel:38";
                            visible: more.text === ""
                            text: "Anything else about it"
                            font: more.font
                            color: Theme.moduleColour("tasks","muted",Theme.textMuted)
                        }
                    }
                }

                // ── ACTIONS ─────────────────────────────────────────────

                // Back, the day as a button, the lane, and Delete. No Done
                // button: the lane is the state. The month opens over the day
                // button; click a day, scroll to page, Escape or click
                // outside to cancel.
                RowLayout { objectName:"design:TasksPanel:39";
                    Layout.fillWidth: true
                    spacing: 8

                    IconButton {
                        icon: "󰁍"
                        iconSize: 14
                        onClicked: root.back()
                    }

                    PillButton {
                        id: dayButton

                        Layout.leftMargin: 6
                        icon: "󰃭"
                        text: sheet.due !== "" ? TasksService.dueLabel(sheet.due) : "Pick a day"
                        active: sheet.picking
                        onClicked: {
                            sheet.picking = !sheet.picking
                            if (!sheet.picking)
                                line.forceActiveFocus()
                        }
                    }

                    SegmentedControl {
                        options: TasksService.states.map(item => ({ id: item.id, label: item.label }))
                        current: root.task ? root.task.state : "todo"
                        onSelected: id => TasksService.setState(sheet.key, id)
                    }

                    Item { objectName:"design:TasksPanel:40"; Layout.fillWidth: true }

                    PillButton {
                        text: "Delete"
                        icon: "󰆴"
                        onClicked: {
                            const direct = TasksService.direct
                            TasksService.remove(sheet.key)
                            if (direct)
                                root.closed()
                        }
                    }
                }
            }

            // ── MONTH ───────────────────────────────────────────────────

            // Over the form while picking a day: a click outside the month
            // closes it, and the month takes the keys so Escape closes it
            // rather than the task.
            MouseArea {
                anchors.fill: parent
                visible: sheet.picking
                z: 5
                onPressed: {
                    sheet.picking = false
                    line.forceActiveFocus()
                }
            }

            Loader {
                id: month

                z: 6
                active: sheet.picking
                sourceComponent: DayPicker {
                    selected: sheet.due
                    onPicked: day => sheet.pick(day)
                    onDismissed: {
                        sheet.picking = false
                        line.forceActiveFocus()
                    }
                }

                // Placed above the button, flush with its left edge, once the
                // month has a size, and grown from there rather than faded in
                // from its last position.
                onLoaded: {
                    const plate = month.item as Item
                    const at = dayButton.mapToItem(sheet, 0, 0)
                    month.x = at.x
                    month.y = at.y - plate.height - 8
                    plate.forceActiveFocus()
                    arrive.restart()
                }

                opacity: 0
                transform: Scale {
                    id: grow
                    origin.x: 0
                    origin.y: month.height
                    xScale: 1
                    yScale: 1
                }

                ParallelAnimation {
                    id: arrive
                    NumberAnimation { target: month; property: "opacity"; from: 0; to: 1; duration: Theme.durationFast; easing.type: Theme.easing }
                    NumberAnimation { target: grow; property: "yScale"; from: 0.94; to: 1; duration: Theme.durationFast; easing.type: Theme.easing }
                    NumberAnimation { target: grow; property: "xScale"; from: 0.98; to: 1; duration: Theme.durationFast; easing.type: Theme.easing }
                }
            }
        }
    }
}
