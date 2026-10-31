// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   G A M E S   B L O C K                                                  │
// │   arcade block · best scores and play                                    │
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

// Arcade block. One row: the mark, the last best and Play. Two rows: the last
// three games.
Card {
    id: root

    property int rows: 1

    signal panelRequested(string panel)

    readonly property string last: GamesService.lastPlayed
    readonly property var lastEntry: GamesService.entry(root.last)

    ColumnLayout { objectName:"design:GamesBlock:1";
        anchors.fill: parent
        spacing: 8

        RowLayout { objectName:"design:GamesBlock:2";
            Layout.fillWidth: true
            spacing: 12

            Rectangle { objectName:"design:GamesBlock:3";
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 10
                color: Qt.rgba(Theme.moduleColour("games","accent",Theme.accent).r, Theme.moduleColour("games","accent",Theme.accent).g, Theme.moduleColour("games","accent",Theme.accent).b, 0.2)

                Text { objectName:"design:GamesBlock:4";
                    anchors.centerIn: parent
                    text: "󰊗"
                    font.family: Theme.fontMono
                    font.pixelSize: 17
                    color: Theme.moduleColour("games","accent",Theme.accent)
                }
            }

            ColumnLayout { objectName:"design:GamesBlock:5";
                Layout.fillWidth: true
                spacing: 1

                Text { objectName:"design:GamesBlock:6";
                    text: "Games"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.moduleColour("games","foreground",Theme.text)
                }

                Text { objectName:"design:GamesBlock:7";
                    Layout.fillWidth: true
                    text: root.lastEntry
                        ? `${root.lastEntry.name} · best ${GamesService.bestOf(root.last)}`
                        : "Nothing played yet"
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLabel
                    color: Theme.moduleColour("games","muted",Theme.textMuted)
                }
            }

            PillButton {
                text: "Play"
                implicitHeight: 26
                onClicked: root.panelRequested("games")
            }
        }

        Repeater {
            model: ScriptModel {
                values: root.rows >= 2 ? GamesService.ranked.slice(0, 3) : []
            }

            RowLayout { objectName:"design:GamesBlock:8";
                id: row

                required property var modelData

                Layout.fillWidth: true
                spacing: 10

                Text { objectName:"design:GamesBlock:9";
                    Layout.preferredWidth: 18
                    horizontalAlignment: Text.AlignHCenter
                    text: row.modelData.icon
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                    color: GamesService.tintOf(row.modelData.id)
                }

                Text { objectName:"design:GamesBlock:10";
                    Layout.fillWidth: true
                    text: row.modelData.name
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.moduleColour("games","foreground",Theme.text)
                }

                Text { objectName:"design:GamesBlock:11";
                    text: `${GamesService.bestOf(row.modelData.id)}`
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeLabel
                    color: Theme.moduleColour("games","muted",Theme.textMuted)
                }
            }
        }

        Item { objectName:"design:GamesBlock:12";
            Layout.fillHeight: true
            visible: root.rows >= 2
        }
    }
}
