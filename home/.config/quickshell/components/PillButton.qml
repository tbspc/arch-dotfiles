// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   P I L L   B U T T O N                                                  │
// │   capsule action · fills with the accent when active                     │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../theme"

// Capsule action button. `active` fills it with the accent, which is how the
// Quick Controls show a radio or profile that is currently on.
Rectangle { objectName:"design:PillButton:1";
    id: root

    property string text: ""
    property string icon: ""
    property bool active: false
    property bool enabled: true
    property int horizontalPadding: 10

    signal clicked()

    readonly property bool filled: root.active
    readonly property color foreground: root.filled ? Theme.accentTextIn(QsWindow.window) : Theme.textIn(QsWindow.window)

    implicitHeight: Theme.controlSizeIn(QsWindow.window, 28)
    implicitWidth: layout.implicitWidth + root.horizontalPadding * 2
    radius:Theme.radiusIn(QsWindow.window,"buttonRadius",Theme.radiusPill)
    opacity: root.enabled ? 1 : 0.4

    color: root.filled
        ? (mouse.containsMouse ? Theme.accentHoverIn(QsWindow.window) : Theme.accentIn(QsWindow.window))
        : (mouse.containsMouse ? Theme.surfaceHoverIn(QsWindow.window) : Theme.surfaceIn(QsWindow.window))
    border.color: root.filled ? Theme.accentIn(QsWindow.window)
        : (mouse.containsMouse ? Theme.accentIn(QsWindow.window) : Theme.borderIn(QsWindow.window))
    border.width: 1

    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }
    Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }

    RowLayout { objectName:"design:PillButton:2";
        id: layout
        anchors.centerIn: parent
        spacing: 6

        Text { objectName:"design:PillButton:3";
            visible: root.icon !== ""
            text: root.icon
            font.family: Theme.fontMono
            font.pixelSize: 12
            color: root.filled ? Theme.accentTextIn(QsWindow.window) : Theme.accentIn(QsWindow.window)
        }

        Text { objectName:"design:PillButton:4";
            visible: root.text !== ""
            text: root.text
            font.family: Theme.fontIn(QsWindow.window)
            font.pixelSize: Theme.textSizeIn(QsWindow.window, Theme.fontSizeSmall)
            font.weight: root.filled ? Font.DemiBold : Font.Normal
            color: root.foreground
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
