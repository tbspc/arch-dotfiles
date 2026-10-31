// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   N O T E S   M O D U L E                                                │
// │   notes · recent notes when open                                         │
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

// The latest notes, one line each, and a button that opens the deck; a row
// opens its note. Editing needs the keyboard, so it happens in the panel.
Item { objectName:"design:NotesModule:1";
    id: root

    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight

    readonly property int count: NotesService.count

    Loader {
        id: holder
        anchors.fill: parent
        sourceComponent: detail
    }

    function openOn(key: string): void {
        NotesService.open(key)
        ModuleService.requestPanel("notes")
    }

    Component {
        id: detail

        ModuleCard {
            title: "Notes"
            subtitle: root.count === 0
                ? "Nothing written down yet"
                : `${root.count} ${root.count === 1 ? "note" : "notes"}`
                    + (NotesService.archived.length > 0
                        ? ` · ${NotesService.archived.length} archived` : "")

            mark: RingIndicator {
                anchors.fill: parent
                thickness: 3
                progress: 0
                trackColor: Theme.indicatorDim

                Text { objectName:"design:NotesModule:2";
                    anchors.centerIn: parent
                    text: "󰎞"
                    font.family: Theme.fontMono
                    font.pixelSize: 20
                    color: Theme.moduleColour("notes","accent",Theme.indicator)
                }
            }

            // The last three, most recently edited first.
            Repeater {
                model: ScriptModel {
                    values: NotesService.live.slice(0, 3)
                    objectProp: "key"
                }

                Item { objectName:"design:NotesModule:3";
                    id: row

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.cardRow

                    // The hover reaches past the row, so its text lines up
                    // with the card's other rows.
                    Rectangle { objectName:"design:NotesModule:4";
                        anchors.fill: parent
                        anchors.leftMargin: -8
                        anchors.rightMargin: -8
                        radius: Theme.radiusSmall
                        color: Theme.surfaceHoverIn(QsWindow.window)
                        opacity: rowMouse.containsMouse ? 1 : 0

                        Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
                    }

                    RowLayout { objectName:"design:NotesModule:5";
                        anchors.fill: parent
                        spacing: 10

                        Rectangle { objectName:"design:NotesModule:6";
                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 8
                            radius: 4
                            color: NotesService.tintColor(row.modelData.tint)
                        }

                        Text { objectName:"design:NotesModule:7";
                            Layout.fillWidth: true
                            text: NotesService.titleOf(row.modelData)
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: NotesService.isEmpty(row.modelData) ? Theme.moduleColour("notes","muted",Theme.textMuted) : Theme.moduleColour("notes","foreground",Theme.text)
                        }

                        Text { objectName:"design:NotesModule:8";
                            text: NotesService.ageOf(row.modelData.edited)
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.moduleColour("notes","muted",Theme.textMuted)
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openOn(row.modelData.key)
                    }
                }
            }

            RowLayout { objectName:"design:NotesModule:9";
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.cardRow
                spacing: 8

                Item { objectName:"design:NotesModule:10"; Layout.fillWidth: true }

                PillButton {
                    implicitHeight: Theme.cardRow
                    text: "New"
                    icon: "󰐕"
                    onClicked: {
                        NotesService.create()
                        ModuleService.requestPanel("notes")
                    }
                }

                PillButton {
                    implicitHeight: Theme.cardRow
                    text: "Open"
                    icon: "󰏫"
                    onClicked: root.openOn("")
                }
            }
        }
    }
}
