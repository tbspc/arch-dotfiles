// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E T T I N G S   H E R O                                              │
// │   settings page heading                                                  │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../theme"

// Settings page header: mark and name, left-aligned, a step larger than the
// group headings.
RowLayout { objectName:"design:SettingsHero:1";
    id: root

    property string icon: ""
    property string title: ""

    spacing: 10

    Text { objectName:"design:SettingsHero:2";
        Layout.leftMargin: 4
        text: root.icon
        font.family: Theme.fontMono
        font.pixelSize: 17
        color: Theme.accentIn(QsWindow.window)
    }

    Text { objectName:"design:SettingsHero:3";
        Layout.fillWidth: true
        text: root.title
        font.family: Theme.fontIn(QsWindow.window)
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.DemiBold
        color: Theme.textIn(QsWindow.window)
    }
}
