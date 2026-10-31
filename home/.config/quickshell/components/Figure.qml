// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   F I G U R E                                                            │
// │   a value with its caption                                               │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../theme"

// One reading in three lines: a small-caps label, the number, and a note.
// The number is monospaced so digits do not shift as it changes.
ColumnLayout { objectName:"design:Figure:1";
    id: root

    property string label: ""
    property string value: ""
    property string note: ""
    property color valueColor: Theme.textIn(QsWindow.window)

    spacing: 1

    Text { objectName:"design:Figure:2";
        text: root.label
        font.family: Theme.fontIn(QsWindow.window)
        font.pixelSize: Theme.fontSizeLabel
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
        color: Theme.mutedIn(QsWindow.window)
    }

    Text { objectName:"design:Figure:3";
        Layout.fillWidth: true
        text: root.value
        elide: Text.ElideRight
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.DemiBold
        color: root.valueColor
    }

    Text { objectName:"design:Figure:4";
        Layout.fillWidth: true
        visible: root.note !== ""
        text: root.note
        elide: Text.ElideRight
        font.family: Theme.fontIn(QsWindow.window)
        font.pixelSize: Theme.fontSizeLabel
        color: Theme.mutedIn(QsWindow.window)
    }
}
