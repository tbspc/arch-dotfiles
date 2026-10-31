// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   D E T A I L   C H O I C E                                              │
// │   one of a list to choose from on a control-centre page                  │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import Quickshell
import "../../theme"

// A row with a name, lit and checked when it is the one in use; its name lines
// up with a `LevelRow`'s, past where the mark would be.
Rectangle { objectName:"design:DetailChoice:1";
    id: root

    property string text: ""
    property bool chosen: false

    signal picked()

    width: parent ? parent.width : 0
    height: Theme.detailRow
    radius: Theme.radiusSmall
    color: root.chosen || pick.containsMouse ? Theme.surfaceHoverIn(QsWindow.window) : Qt.alpha(Theme.surfaceHoverIn(QsWindow.window), 0)

    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

    Text { objectName:"design:DetailChoice:2";
        x: 30
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 64
        elide: Text.ElideRight
        text: root.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeRegular - 1
        color: Theme.moduleColour("_shared","foreground",Theme.text)
    }

    Text { objectName:"design:DetailChoice:3";
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        visible: root.chosen
        text: "󰄬"
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontSizeRegular
        color: Theme.moduleColour("_shared","accent",Theme.accent)
    }

    MouseArea {
        id: pick

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
    }
}
