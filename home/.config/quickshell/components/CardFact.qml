// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C A R D   F A C T                                                      │
// │   one fact on a card · its name, then its value on the right             │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../theme"

// A reading that is not a share: a wattage, a count, a place. Monospaced, so
// digits do not shift as it changes.
RowLayout { objectName:"design:CardFact:1";
    id: root

    property string name: ""
    property string value: ""
    property color valueColor: Theme.textIn(QsWindow.window)

    Layout.fillWidth: true
    Layout.preferredHeight: Theme.cardRow
    spacing: 10

    Text { objectName:"design:CardFact:2";
        Layout.fillWidth: true
        text: root.name
        elide: Text.ElideRight
        font.family: Theme.fontIn(QsWindow.window)
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.mutedIn(QsWindow.window)
    }

    Text { objectName:"design:CardFact:3";
        Layout.maximumWidth: 260
        text: root.value
        elide: Text.ElideLeft
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontSizeSmall
        color: root.valueColor
    }
}
