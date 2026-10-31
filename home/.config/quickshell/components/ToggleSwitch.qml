// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   T O G G L E   S W I T C H                                              │
// │   an on/off control for a settings row                                   │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import Quickshell
import "../theme"

// The knob slides rather than jumping, so the switch shows which way it
// went. Disabled, it fades instead of turning grey.
Rectangle { objectName:"design:ToggleSwitch:1";
    id: root

    property bool checked: false
    readonly property bool modern: Theme.modernIn(QsWindow.window)

    signal toggled(bool checked)

    implicitWidth: root.modern ? 38 : Theme.controlSizeIn(QsWindow.window, 22) > 22 ? 48 : 40
    implicitHeight: root.modern ? 22 : Math.min(28, Theme.controlSizeIn(QsWindow.window, 22))
    radius: height / 2
    opacity: root.enabled ? 1 : 0.45

    Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }

    color: root.checked ? Theme.accentIn(QsWindow.window) : Theme.surfaceHoverIn(QsWindow.window)
    border.color: root.checked ? Theme.accentIn(QsWindow.window) : Theme.borderIn(QsWindow.window)
    border.width: root.modern ? 0 : 1

    Behavior on color { ColorAnimation { duration: root.modern ? 300 : Theme.durationFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

    Rectangle { objectName:"design:ToggleSwitch:2";
        y: root.modern ? 2 : 3
        x: root.checked ? root.width - width - y : y
        width: root.height - 2*y
        height: width
        radius: width / 2
        color: root.modern ? "#fefdfb" : root.checked ? Theme.accentTextIn(QsWindow.window) : Theme.mutedIn(QsWindow.window)

        Behavior on x { NumberAnimation { duration:root.modern?220:Theme.durationFast; easing.type:root.modern?Easing.OutBack:Theme.easing; easing.overshoot:.35 } }
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.toggled(!root.checked)
    }
}
