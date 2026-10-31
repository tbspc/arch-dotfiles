// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E T T I N G   S L I D E R                                            │
// │   a number you drag, with the number on it                               │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls

import "../theme"
import "../services"

// A setting row with a continuous value (a height, a radius, a blur): the
// name on the left, the track and its figure on the same line at the right.
//
// Clicking the figure turns it into a field for an exact number: Enter
// commits, Escape cancels, arrows step. The mouse wheel steps too, over the
// track only, so scrolling the page never changes a value.
//
// The track is drawn here; the Controls slider on top is invisible and only
// supplies the drag behaviour.
Item { objectName:"design:SettingSlider:1";
    id: root

    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property int decimals: 0
    property string unit: ""

    // Overridable, e.g. a blur of zero reads "Off".
    property string reading:
        `${root.value.toFixed(root.decimals)}${root.unit}`

    // Same meaning as in `SettingRow`.
    property bool locked: false
    property string reason: ""

    signal moved(real value)

    Layout.fillWidth: true
    implicitHeight: Math.max(SettingsDesignService.style.rowHeight,body.implicitHeight+2*SettingsDesignService.style.rowPadding)
    opacity: root.locked ? 0.55 : 1

    Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }

    SettingDivider {}

    RowLayout { objectName:"design:SettingSlider:2";
        id: body

        anchors.fill: parent
        anchors.leftMargin:SettingsDesignService.forma?SettingsDesignService.style.cardPadding:14
        anchors.rightMargin:SettingsDesignService.forma?SettingsDesignService.style.cardPadding:14
        spacing: 12

        SettingLabel {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            label: root.label
            locked: root.locked
            reason: root.reason
        }

        Item { objectName:"design:SettingSlider:3";
            Layout.preferredWidth: 240
            Layout.preferredHeight: Math.max(24, SettingsDesignService.style.sliderThumbSize || 16)
            Layout.alignment: Qt.AlignVCenter
            enabled: !root.locked

            Rectangle { objectName:"design:SettingSlider:4";
                id: track

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: SettingsDesignService.style.sliderTrackHeight || 4
                radius: 2
                color: Theme.surfaceHoverIn(QsWindow.window)

                Rectangle { objectName:"design:SettingSlider:5";
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * slider.position
                    radius: parent.radius
                    color: Theme.accentIn(QsWindow.window)
                }
            }

            Rectangle { objectName:"design:SettingSlider:6";
                x: track.width * slider.position - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(SettingsDesignService.style.sliderThumbSize || 0, slider.pressed || slider.hovered ? 16 : 13)
                height: width
                radius: width / 2
                color: Theme.accentTextIn(QsWindow.window)
                border.color: Theme.accentIn(QsWindow.window)
                border.width: 3

                Behavior on width {
                    NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
                }
            }

            Slider {
                id: slider

                anchors.fill: parent
                from: root.from
                to: root.to
                stepSize: root.stepSize
                opacity: 0
                onMoved: root.moved(slider.value)
            }

            // One step per notch, mouse only: a touchpad fling would jump
            // many steps.
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse
                onWheel: event => {
                    const direction = event.angleDelta.y > 0 ? 1 : -1
                    root.moved(Math.min(root.to, Math.max(root.from,
                        root.value + direction * root.stepSize)))
                }
            }

            // Dragging breaks a plain binding on `slider.value`; this keeps
            // the track following external changes such as a reset.
            Binding {
                target: slider
                property: "value"
                value: root.value
                when: !slider.pressed
                restoreMode: Binding.RestoreBindingOrValue
            }
        }

        Item { objectName:"design:SettingSlider:7";
            id: readingSlot

            property bool editing: false

            Layout.preferredWidth: readingSlot.editing
                ? 68 : Math.max(48, readout.implicitWidth)
            Layout.preferredHeight: 22
            Layout.alignment: Qt.AlignVCenter
            enabled: !root.locked

            // Clamped and snapped to the slider's steps.
            function commit(entered: string): void {
                const parsed = parseFloat(entered.replace(",", "."))
                if (isNaN(parsed))
                    return
                let wanted = Math.min(root.to, Math.max(root.from, parsed))
                if (root.stepSize > 0)
                    wanted = root.from + Math.round(
                        (wanted - root.from) / root.stepSize) * root.stepSize
                wanted = Math.min(root.to, Math.max(root.from, wanted))
                root.moved(wanted)
            }

            function nudge(direction: int): void {
                const wanted = Math.min(root.to, Math.max(root.from,
                    root.value + direction * root.stepSize))
                root.moved(wanted)
                editor.text = wanted.toFixed(root.decimals)
            }

            Text { objectName:"design:SettingSlider:8";
                id: readout

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: !readingSlot.editing
                text: root.reading
                font.family: Theme.fontMono
                font.pixelSize: Theme.textSizeIn(QsWindow.window, Theme.fontSizeSmall)
                color: Theme.textIn(QsWindow.window)

                Behavior on color { ColorAnimation { duration: Theme.durationFast } }
            }

            MouseArea {
                id: readingMouse

                anchors.fill: parent
                visible: !readingSlot.editing
                hoverEnabled: true
                cursorShape: Qt.IBeamCursor
                onClicked: {
                    readingSlot.editing = true
                    editor.text = root.value.toFixed(root.decimals)
                    editor.forceActiveFocus()
                    editor.selectAll()
                }
            }

            Rectangle { objectName:"design:SettingSlider:9";
                anchors.fill: parent
                visible: readingSlot.editing
                radius: Theme.radiusSmall - 2
                color: Theme.island
                border.color: Theme.accentIn(QsWindow.window)
                border.width: 1

                TextInput { objectName:"design:SettingSlider:10";
                    id: editor

                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.textSizeIn(QsWindow.window, Theme.fontSizeSmall)
                    color: Theme.textIn(QsWindow.window)
                    selectByMouse: true
                    selectionColor: Theme.accentIn(QsWindow.window)
                    selectedTextColor: Theme.accentTextIn(QsWindow.window)
                    clip: true
                    validator: RegularExpressionValidator {
                        regularExpression: /-?[0-9]*[.,]?[0-9]*/
                    }

                    Keys.onEscapePressed: readingSlot.editing = false
                    Keys.onUpPressed: readingSlot.nudge(1)
                    Keys.onDownPressed: readingSlot.nudge(-1)

                    // Enter or focus loss. Escape has already cleared
                    // `editing`, so it does not commit.
                    onEditingFinished: {
                        if (!readingSlot.editing)
                            return
                        readingSlot.editing = false
                        readingSlot.commit(editor.text)
                    }
                }
            }
        }
    }
}
