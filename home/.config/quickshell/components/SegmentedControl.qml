// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E G M E N T E D   C O N T R O L                                      │
// │   pick one of a few, with all of them visible                            │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../theme"

// For two or three options, all visible at once.
Rectangle { objectName:"design:SegmentedControl:1";
    id: root

    // Entries of { id, label }, or { id, label, icon }: an entry with an icon
    // shows only the glyph, and its label appears above the control on hover.
    property var options: []
    property string current: ""
    readonly property bool modern: Theme.modernIn(QsWindow.window)
    property int selectionRevision: 0
    readonly property Item selectedSegment: {const revision = root.selectionRevision; return segments.count ? segments.itemAt(root.options.findIndex(o => o.id === root.current)) : null }
    property int iconSize: Theme.fontSizeLarge
    // Distance from the control's top edge to the hovered label.
    property int tipGap: 6

    signal selected(string id)

    // The segment under the pointer.
    property Item hovered: null

    implicitWidth: layout.implicitWidth + 6
    implicitHeight: Theme.controlSizeIn(QsWindow.window, 28)
    radius:Theme.radiusIn(QsWindow.window,"controlRadius",Theme.radiusSmall)
    opacity: root.enabled ? 1 : 0.45

    Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
    color: Theme.surfaceHoverIn(QsWindow.window)
    border.color: Theme.borderIn(QsWindow.window)
    border.width: root.modern ? 0 : 1

    Rectangle {
        visible: root.modern && root.selectedSegment !== null
        x: layout.x + (root.selectedSegment ? root.selectedSegment.x : 0)
        y: 3; height: root.height - 6
        width: root.selectedSegment ? root.selectedSegment.width : 0
        radius: 6
        color: Theme.colourIn(QsWindow.window,"cardBackground","#fefdfb")
        border.width: 1; border.color: Qt.alpha(Theme.borderIn(QsWindow.window),.5)
        Behavior on x { enabled: root.modern && root.visible; SpringAnimation { spring: 5; damping: .42; epsilon: .1 } }
        Behavior on width { enabled: root.modern && root.visible; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    RowLayout { objectName:"design:SegmentedControl:2";
        id: layout
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            id: segments
            onItemAdded: root.selectionRevision++
            onItemRemoved: root.selectionRevision++
            model: root.options

            Rectangle { objectName:"design:SegmentedControl:3";
                id: segment

                required property var modelData
                readonly property bool active: segment.modelData.id === root.current
                readonly property bool glyph: (segment.modelData.icon ?? "") !== ""

                Layout.preferredHeight: root.implicitHeight - 6
                Layout.preferredWidth: segment.glyph
                    ? Layout.preferredHeight
                    : Math.max(64, label.implicitWidth + 20)
                radius:Theme.radiusIn(QsWindow.window,"controlRadius",Theme.radiusSmall) - 2
                color: root.modern ? (segmentMouse.containsMouse && !segment.active ? Qt.alpha(Theme.borderIn(QsWindow.window),.35) : "transparent") : segment.active ? Theme.accentIn(QsWindow.window)
                    : (segmentMouse.containsMouse ? Theme.borderIn(QsWindow.window) : Qt.alpha(Theme.borderIn(QsWindow.window), 0))

                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                Text { objectName:"design:SegmentedControl:4";
                    id: label
                    anchors.centerIn: parent
                    text: segment.glyph ? segment.modelData.icon : segment.modelData.label
                    font.family: segment.glyph ? Theme.fontMono : Theme.fontIn(QsWindow.window)
                    font.pixelSize: segment.glyph ? root.iconSize : Theme.fontSizeSmall
                    font.weight: segment.active ? Font.DemiBold : Font.Normal
                    color: segment.active ? (root.modern ? Theme.textIn(QsWindow.window) : Theme.accentTextIn(QsWindow.window))
                        : (segment.glyph && segmentMouse.containsMouse ? Theme.textIn(QsWindow.window)
                                                                        : Theme.mutedIn(QsWindow.window))
                }

                MouseArea {
                    id: segmentMouse
                    anchors.fill: parent
                    enabled: root.enabled
                    hoverEnabled: true
                    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.selected(segment.modelData.id)
                    onContainsMouseChanged: {
                        if (containsMouse)
                            root.hovered = segment
                        else if (root.hovered === segment)
                            root.hovered = null
                    }
                }
            }
        }
    }

    // ── LABEL ───────────────────────────────────────────────────────────────
    //
    // The hovered glyph's name, centred over it. It keeps the last segment
    // through the fade-out, so the name does not blank before it is gone.

    Rectangle { objectName:"design:SegmentedControl:5";
        id: tip

        property Item target: null

        Binding on target {
            when: root.hovered !== null && root.hovered.glyph
            value: root.hovered
            restoreMode: Binding.RestoreNone
        }

        visible: opacity > 0
        opacity: root.hovered !== null && root.hovered.glyph ? 1 : 0
        x: tip.target === null ? 0
            : layout.x + tip.target.x + (tip.target.width - tip.width) / 2
        y: -tip.height - root.tipGap
        width: tipText.implicitWidth + 20
        height: 26
        radius: height / 2
        color: Theme.island
        border.color: Theme.borderIn(QsWindow.window)
        border.width: 1

        Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
        Behavior on x {
            enabled: tip.opacity > 0
            NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }

        Text { objectName:"design:SegmentedControl:6";
            id: tipText
            anchors.centerIn: parent
            text: tip.target === null ? "" : tip.target.modelData.label
            font.family: Theme.fontIn(QsWindow.window)
            font.pixelSize: Theme.textSizeIn(QsWindow.window, Theme.fontSizeSmall)
            font.weight: Font.DemiBold
            color: Theme.textIn(QsWindow.window)
        }
    }
}
