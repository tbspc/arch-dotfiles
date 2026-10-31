// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   G R O U P   H E A D I N G                                              │
// │   settings group heading · with optional details                         │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../theme"
import "../services"

// A settings group's name, in the sidebar's small capitals. `note` and `hint`
// open together behind the info glyph, by click rather than hover so the page
// does not shift under the pointer.
ColumnLayout { objectName:"design:GroupHeading:1";
    id: root

    property string title: ""
    property string note: ""
    property string hint: ""

    property bool opened: false

    readonly property string told:
        [root.note, root.hint].filter(text => text !== "").join(" ")

    Layout.fillWidth: true
    spacing: 4

    RowLayout { objectName:"design:GroupHeading:2";
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 7

        Text { objectName:"design:GroupHeading:3";
            text: root.title
            font.family: Theme.fontIn(QsWindow.window)
            font.pixelSize: Theme.modernIn(QsWindow.window) ? 12 : Theme.fontSizeLabel
            font.weight: Font.DemiBold
            font.letterSpacing: Theme.modernIn(QsWindow.window) ? 0 : 0.8
            font.capitalization: Theme.modernIn(QsWindow.window) ? Font.MixedCase : Font.AllUppercase
            color: Theme.mutedIn(QsWindow.window)
        }

        Text { objectName:"design:GroupHeading:4";
            visible:root.told!=="" && (!Theme.formaIn(QsWindow.window)||SettingsDesignService.style.showHelp)
            text: "󰋼"
            font.family: Theme.fontMono
            font.pixelSize: 10
            color: root.opened ? Theme.accentIn(QsWindow.window) : Theme.mutedIn(QsWindow.window)
            opacity: root.opened || hintMouse.containsMouse ? 1 : 0.5

            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
            Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }

            MouseArea {
                id: hintMouse
                anchors.fill: parent
                anchors.margins: -5
                hoverEnabled: true
                cursorShape: Qt.WhatsThisCursor
                onClicked: root.opened = !root.opened
            }
        }

        Item { objectName:"design:GroupHeading:5"; Layout.fillWidth: true }
    }

    Text { objectName:"design:GroupHeading:6";
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 20
        Layout.bottomMargin: 2
        visible: root.opened && root.told !== ""
        text: root.told
        wrapMode: Text.WordWrap
        font.family: Theme.fontIn(QsWindow.window)
        font.pixelSize: Theme.modernIn(QsWindow.window) ? 12 : Theme.fontSizeLabel
        color: Theme.mutedIn(QsWindow.window)
    }
}
