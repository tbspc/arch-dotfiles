// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   U S A G E   B A R S                                                    │
// │   screen time · stacked bars, a shade of the accent per group            │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import QtQuick.Shapes

import "../theme"

// One bar per bucket, each split bottom up into the ranked groups and the
// rest (`ScreenTimeService.digest`'s stacks). An hour holds an hour; days are
// scaled to the busiest, with the average dashed across when there is one.
Item { objectName:"design:UsageBars:1";
    id: root

    property var stacks: []
    property real ceiling: 0
    property real average: 0
    property real gap: 3
    property color accent: Theme.accentIn(QsWindow.window)
    property color ink: Theme.textIn(QsWindow.window)
    property color track: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.06)

    readonly property real peak: {
        if (root.ceiling > 0)
            return root.ceiling
        let most = root.average
        for (const parts of root.stacks)
            most = Math.max(most, parts.reduce((a, b) => a + b, 0))
        return Math.max(3600, Math.ceil(most * 1.08 / 3600) * 3600)
    }
    readonly property real slot: (root.width + root.gap) / Math.max(1, root.stacks.length)

    Repeater {
        model: root.stacks.length

        Item { objectName:"design:UsageBars:2";
            id: bar

            required property int index

            readonly property var parts: root.stacks[bar.index]

            x: bar.index * root.slot
            width: Math.max(1, root.slot - root.gap)
            height: root.height

            Rectangle { objectName:"design:UsageBars:3";
                anchors.fill: parent
                radius: Math.min(3, width / 2)
                color: root.track
            }

            Column { objectName:"design:UsageBars:4";
                anchors.bottom: parent.bottom
                width: bar.width

                Repeater {
                    model: bar.parts.length

                    Rectangle { objectName:"design:UsageBars:5";
                        required property int index

                        readonly property int rank: bar.parts.length - 1 - index

                        width: bar.width
                        height: Math.round(root.height * Math.min(1, bar.parts[rank] / root.peak))
                        color: Theme.rankColorIn(rank < bar.parts.length - 1 ? rank : -1, root.accent, root.ink)
                    }
                }
            }
        }
    }

    Shape {
        id: line

        readonly property real level: root.height * (1 - root.average / root.peak)

        anchors.fill: parent
        visible: root.average > 0

        ShapePath {
            strokeColor: root.ink
            strokeWidth: 1
            strokeStyle: ShapePath.DashLine
            dashPattern: [3, 3]
            fillColor: "transparent"
            startX: 0
            startY: line.level

            PathLine { x: root.width; y: line.level }
        }
    }
}
