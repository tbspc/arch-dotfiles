// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C A R D   L E V E L                                                    │
// │   one level on a card · its name, a line to drag, its value              │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Controls
import QtQuick.Layouts

import "../theme"

// A level that can be set — a volume, a brightness — drawn as a limit is
// (`CardLimit`), with a knob: the two read as one family on a card. The name
// is a glyph or an application's picture and a word; a click on it is
// `markClicked`, which mutes.
RowLayout { objectName:"design:CardLevel:1";
    id: root

    property var appearance:({})
    property string glyph: ""
    property string picture: ""
    property string name: ""
    property int value: 0
    property bool dimmed: false
    property bool available: true

    signal moved(int value)
    signal markClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(Theme.cardRow,(root.appearance.iconSize??16)+8,(root.appearance.barHeight??6)+10)
    spacing: 10

    Item { objectName:"design:CardLevel:2";
        Layout.preferredWidth: Theme.cardLabel
        Layout.fillHeight: true
        opacity: root.dimmed ? 0.5 : 1

        Row { objectName:"design:CardLevel:3";
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 7

            Image { objectName:"design:CardLevel:4";
                id: picture

                width: root.appearance.iconSize??16
                height: width
                anchors.verticalCenter: parent.verticalCenter
                visible: root.picture !== "" && status === Image.Ready
                source: root.picture
                sourceSize.width: 32
                sourceSize.height: 32
                asynchronous: true
            }

            Text { objectName:"design:CardLevel:5";
                anchors.verticalCenter: parent.verticalCenter
                visible: !picture.visible && root.glyph !== ""
                text: root.glyph
                font.family: Theme.fontMono
                font.pixelSize: root.appearance.iconSize??Theme.fontSizeRegular
                color: Theme.textIn(QsWindow.window)
            }

            Text { objectName:"design:CardLevel:6";
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x
                text: root.name
                elide: Text.ElideRight
                font.family: Theme.fontIn(QsWindow.window)
                font.pixelSize: root.appearance.textSize??Theme.fontSizeSmall
                color: Theme.textIn(QsWindow.window)
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.markClicked()
        }
    }

    Slider {
        id: slider

        Layout.fillWidth: root.appearance.barWidth===undefined
        Layout.preferredWidth:root.appearance.barWidth??-1
        Layout.maximumWidth:Math.max(40,root.width-Theme.cardLabel-68)
        Layout.fillHeight: true
        enabled: root.available
        from: 0
        to: 100
        stepSize: 1
        value: root.value
        onMoved: root.moved(Math.round(slider.value))

        background: Item {
            Rectangle { objectName:"design:CardLevel:7";
                y: (slider.height - height) / 2
                width: slider.width
                height: root.appearance.barHeight??6
                radius: height/2
                color: Theme.surfaceHoverIn(QsWindow.window)

                Rectangle { objectName:"design:CardLevel:8";
                    width: slider.handle.x + slider.handle.width / 2
                    height: parent.height
                    radius: parent.radius
                    color: root.dimmed ? Theme.mutedIn(QsWindow.window) : Theme.accentIn(QsWindow.window)
                }
            }
        }

        handle: Rectangle {
            x: slider.visualPosition * (slider.width - width)
            y: (slider.height - height) / 2
            width: 12
            height: 12
            radius: 6
            color: Theme.textIn(QsWindow.window)
            scale: slider.pressed || slider.hovered ? 1.15 : 1

            Behavior on scale { NumberAnimation { duration: Theme.durationFast } }
        }

        WheelHandler {
            onWheel: event => root.moved(Math.max(0, Math.min(100,
                root.value + (event.angleDelta.y > 0 ? 5 : -5))))
        }
    }

    Text { objectName:"design:CardLevel:9";
        Layout.preferredWidth: Math.max(36,implicitWidth)
        horizontalAlignment: Text.AlignRight
        text: root.dimmed ? "off" : `${root.value}%`
        font.family: Theme.fontMono
        font.pixelSize: root.appearance.textSize??Theme.fontSizeSmall
        color: root.dimmed ? Theme.mutedIn(QsWindow.window) : Theme.textIn(QsWindow.window)
    }
}
