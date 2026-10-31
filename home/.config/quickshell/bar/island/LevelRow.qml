// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   L E V E L   R O W                                                      │
// │   one level on a control-centre page · its name, then its bar            │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell

import "../../theme"
import "../../components"

// Every level on the sound page is one of these: a column of fixed width with
// the mark and the name, then the bar, so every bar on the page starts at the
// same place and is the same size. The mark is a glyph or an application's
// icon; a click on it is `markClicked`, which mutes it.
Item { objectName:"design:LevelRow:1";
    id: root

    property var appearance:({})
    property string glyph: ""
    property string picture: ""
    property string name: ""
    property int value: 0
    property int from: 0
    property int to: 100
    property string unit: "%"
    property bool dimmed: false
    property bool available: true

    signal moved(int value)
    signal markClicked()

    width: parent ? parent.width : 0
    height: Math.max(Theme.detailRow,(root.appearance.iconSize??20)+8)

    Item { objectName:"design:LevelRow:2";
        id: mark

        width: root.appearance.iconSize??20
        height: width
        anchors.verticalCenter: parent.verticalCenter
        opacity: root.dimmed ? 0.45 : 1

        Image { objectName:"design:LevelRow:3";
            id: picture

            anchors.fill: parent
            source: root.picture
            visible: root.picture !== "" && status === Image.Ready
            sourceSize.width: 40
            sourceSize.height: 40
            asynchronous: true
        }

        Text { objectName:"design:LevelRow:4";
            anchors.centerIn: parent
            visible: !picture.visible
            text: root.glyph !== "" ? root.glyph : "󰝚"
            font.family: Theme.fontMono
            font.pixelSize: root.appearance.iconSize??Theme.fontSizeMedium
            color: Theme.moduleColour("_shared","foreground",Theme.text)
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: root.markClicked()
        }
    }

    Text { objectName:"design:LevelRow:5";
        id: label

        anchors.left: mark.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.detailLabel - mark.width - 10
        elide: Text.ElideRight
        text: root.name
        font.family: Theme.fontFamily
        font.pixelSize: root.appearance.textSize??Theme.fontSizeRegular-1
        color: root.dimmed ? Theme.moduleColour("_shared","muted",Theme.textMuted) : Theme.moduleColour("_shared","foreground",Theme.text)
    }

    SliderRow {
        x: Theme.detailLabel + 8
        width:Math.min(parent.width-x,root.appearance.barWidth??parent.width-x)
        height:root.appearance.barHeight??Theme.detailRow-4
        appearance:root.appearance
        anchors.verticalCenter: parent.verticalCenter
        value: root.value
        from: root.from
        to: root.to
        unit: root.unit
        dimmed: root.dimmed
        available: root.available
        onMoved: value => root.moved(value)
    }
}
