// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S T A T   C A R D                                                      │
// │   a figure, its history and whatever detail belongs under it             │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../theme"

// The sparkline sits behind the reading as the card's background.
Card {
    id: root

    property string icon: ""
    property string title: ""
    property string reading: ""
    property string detail: ""
    property var series: []
    property real maximum: 1
    property color accent: Theme.accentIn(QsWindow.window)

    default property alias extra: extraHolder.data

    padding: 0

    // Stops above the extra row, so it never overlaps the per-core bars.
    Sparkline {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        anchors.bottom: parent.bottom
        anchors.bottomMargin: extraHolder.implicitHeight > 0
            ? extraHolder.implicitHeight + 20 : 1
        height: Math.max(28, parent.height * 0.58 - extraHolder.implicitHeight)
        values: root.series
        maximum: root.maximum
        stroke: root.accent
    }

    ColumnLayout { objectName:"design:StatCard:1";
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout { objectName:"design:StatCard:2";
            Layout.fillWidth: true
            spacing: 9

            Text { objectName:"design:StatCard:3";
                text: root.icon
                font.family: Theme.fontMono
                font.pixelSize: 15
                color: root.accent
            }

            Text { objectName:"design:StatCard:4";
                text: root.title
                font.family: Theme.fontIn(QsWindow.window)
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                color: Theme.textIn(QsWindow.window)
            }

            Item { objectName:"design:StatCard:5"; Layout.fillWidth: true }

            Text { objectName:"design:StatCard:6";
                text: root.reading
                font.family: Theme.fontIn(QsWindow.window)
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.DemiBold
                color: Theme.textIn(QsWindow.window)
            }
        }

        Text { objectName:"design:StatCard:7";
            Layout.fillWidth: true
            text: root.detail
            elide: Text.ElideRight
            font.family: Theme.fontIn(QsWindow.window)
            font.pixelSize: Theme.fontSizeLabel
            color: Theme.mutedIn(QsWindow.window)
        }

        Item { objectName:"design:StatCard:8"; Layout.fillHeight: true }

        // A ColumnLayout, not an Item: children need a width, and a bare
        // Item's childrenRect gives them none.
        ColumnLayout { objectName:"design:StatCard:9";
            id: extraHolder
            Layout.fillWidth: true
            spacing: 6
        }
    }
}
