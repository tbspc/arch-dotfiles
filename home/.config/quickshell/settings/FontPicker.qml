// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   F O N T   P I C K E R                                                  │
// │   every family rendered in itself                                        │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import Quickshell

import "../theme"

// Each row is rendered in the family it names.
Rectangle {
    id: root

    property var families: []
    property string current: ""
    property string sample: ""
    property string warning: ""

    signal picked(string family)

    // Sits in a `SettingBlock`, on the group's card.
    color: "transparent"
    clip: true

    // The stored value may be a comma-separated stack; the first entry is
    // the one selected.
    readonly property string preferred: root.current.split(",")[0].trim()

    Text {
        anchors.centerIn: parent
        visible: root.families.length === 0
        text: "Reading installed fonts…"
        font.family: Theme.fontIn(QsWindow.window)
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.mutedIn(QsWindow.window)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 1
        spacing: 0
        visible: root.families.length > 0

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: ScriptModel {
                values: root.families
            }
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: root.families.indexOf(root.preferred)

            delegate: Rectangle {
                id: row

                required property string modelData
                readonly property bool active: row.modelData === root.preferred

                width: ListView.view.width
                height: 30
                radius: Theme.radiusSmall
                color: row.active ? Theme.colourIn(QsWindow.window,"hoverColor",Theme.islandSurfaceHover)
                    : (rowMouse.containsMouse ? Theme.islandBorder : Qt.alpha(Theme.islandBorder, 0))

                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 11
                    anchors.rightMargin: 11
                    spacing: 10

                    Text {
                        text: row.modelData
                        font.family: row.modelData
                        font.pixelSize: Theme.fontSizeSmall
                        color: row.active ? Theme.accentIn(QsWindow.window) : Theme.textIn(QsWindow.window)
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.sample
                        font.family: row.modelData
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.mutedIn(QsWindow.window)
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: row.active
                        text: "󰄬"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: Theme.accentIn(QsWindow.window)
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(row.modelData)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.warning === "" ? 0 : 24
            visible: root.warning !== ""
            radius: Theme.radiusSmall
            color: Theme.colourIn(QsWindow.window,"hoverColor",Theme.islandSurfaceHover)

            Text {
                anchors.fill: parent
                anchors.leftMargin: 11
                verticalAlignment: Text.AlignVCenter
                text: root.warning
                font.family: Theme.fontIn(QsWindow.window)
                font.pixelSize: 9
                color: Theme.yellow
            }
        }
    }
}
