// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   M O T I O N   P R E V I E W                                            │
// │   a window opening on one preset's curve                                 │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import Quickshell
import "../theme"
import "../services"

// A window arriving on a tiny screen with the preset's curve and duration:
// popping in for popin presets, sliding for slide presets, appearing
// instantly for "None", or fading for the opacity-only choices.
//
// Qt's bezier easing needs the end point spelled out, hence the trailing 1, 1.
Item { objectName:"design:MotionPreview:1";
    id: root

    // A row from `Motion.presets`.
    property var preset: null
    property bool animate: true

    readonly property bool still: !root.preset || !root.preset.curve
    readonly property bool fadeOnly: root.preset && root.preset.fadeOnly === true
    readonly property bool slides: !root.fadeOnly
        && root.preset && String(root.preset.windows ?? "").startsWith("slide")
    readonly property real startScale: {
        if (!root.preset || root.fadeOnly || root.slides)
            return 1
        const match = String(root.preset.windows ?? "").match(/popin\s+(\d+)%/)
        return match ? Math.max(.2,1-(1-Number(match[1])/100)*SettingsService.windowAnimationAmount/100) : .8
    }
    readonly property var bezier: root.still ? [0, 0, 1, 1, 1, 1] : [
        root.preset.curve[0], root.preset.curve[1],
        root.preset.curve[2], Math.min(1,root.preset.curve[3])+Math.max(0,root.preset.curve[3]-1)*SettingsService.windowAnimationBounce/100, 1, 1]
    // Hyprland counts in deciseconds, so 2.6 is 260 ms. `slow` is the speed
    // windowsIn actually runs at.
    readonly property int span: root.still ? 0
        : (root.fadeOnly ? root.preset.medium : root.preset.slow) * 100 *100/Math.max(25,SettingsService.windowAnimationSpeed)

    implicitWidth: 92
    implicitHeight: 46

    Rectangle { objectName:"design:MotionPreview:2";
        id: screen

        anchors.fill: parent
        radius: 5
        color: Theme.island
        border.color: Theme.borderIn(QsWindow.window)
        border.width: 1
        clip: true

        Rectangle { objectName:"design:MotionPreview:3";
            id: win

            property bool shown: false

            anchors.horizontalCenter: parent.horizontalCenter
            y: (parent.height - height) / 2
                + (root.slides && !win.shown ? 12 : 0)
            width: parent.width - 20
            height: parent.height - 16
            radius: 4
            color: Theme.accentIn(QsWindow.window)
            scale: root.slides || root.fadeOnly ? 1 : (win.shown ? 1 : root.startScale)
            opacity: win.shown ? 1 : 0

            Behavior on opacity {
                enabled: root.fadeOnly && !root.still
                NumberAnimation {
                    duration: root.span
                    easing.type: Easing.Bezier
                    easing.bezierCurve: root.bezier
                }
            }

            Behavior on scale {
                enabled: !root.still
                NumberAnimation {
                    duration: root.span
                    easing.type: Easing.Bezier
                    easing.bezierCurve: root.bezier
                }
            }

            Behavior on y {
                enabled: !root.still
                NumberAnimation {
                    duration: root.span
                    easing.type: Easing.Bezier
                    easing.bezierCurve: root.bezier
                }
            }

            Timer {
                interval: 1300
                running: root.animate && !root.still
                repeat: true
                triggeredOnStart: true
                onTriggered: win.shown = !win.shown
            }
        }
    }
}
