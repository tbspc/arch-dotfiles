// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E T T I N G   L A B E L                                              │
// │   settings · a row's name and reading                                    │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../theme"

// The left half of every settings row: the name, and under it what the
// setting says now — or, locked, a padlock and why it cannot change.
ColumnLayout { objectName:"design:SettingLabel:1";
    id: root

    property string label: ""
    property string reading: ""
    property bool alarm: false
    property bool locked: false
    property string reason: ""

    spacing: 1

    Text { objectName:"design:SettingLabel:2";
        Layout.fillWidth: true
        text: root.label
        wrapMode: Text.WordWrap
        font.family: Theme.fontIn(QsWindow.window)
        font.pixelSize: Theme.textSizeIn(QsWindow.window, Theme.fontSizeSmall)
        font.weight: Font.Medium
        color: Theme.textIn(QsWindow.window)
    }

    RowLayout { objectName:"design:SettingLabel:3";
        Layout.fillWidth: true
        visible: root.locked ? root.reason !== "" : root.reading !== ""
        spacing: 5

        Text { objectName:"design:SettingLabel:4";
            visible: root.locked
            text: "󰌾"
            font.family: Theme.fontMono
            font.pixelSize: 9
            color: Theme.mutedIn(QsWindow.window)
        }

        Text { objectName:"design:SettingLabel:5";
            Layout.fillWidth: true
            text: root.locked ? root.reason : root.reading
            wrapMode: Text.WordWrap
            font.family: Theme.fontIn(QsWindow.window)
            font.pixelSize: Math.max(Theme.fontSizeLabel, Theme.textSizeIn(QsWindow.window, 0)-2)
            color: root.alarm && !root.locked ? Theme.red : Theme.mutedIn(QsWindow.window)
        }
    }
}
