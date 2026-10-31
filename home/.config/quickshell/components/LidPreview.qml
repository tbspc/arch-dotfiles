// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   L I D   P R E V I E W                                                  │
// │   a laptop and a monitor, and which of them is lit                       │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import Quickshell
import "../theme"

// A laptop beside a monitor, showing which screen stays lit when the lid
// closes. Not to scale.
Item { objectName:"design:LidPreview:1";
    id: root

    // Whether the laptop's own panel is lit behind the closed lid.
    property bool lit: false

    // Whether a second screen is drawn. The "let the system decide" tile shows
    // the laptop alone.
    property bool external: true

    implicitWidth: 104
    implicitHeight: 52

    Row { objectName:"design:LidPreview:2";
        anchors.centerIn: parent
        spacing: 10

        // The laptop, lid partly closed.
        Column { objectName:"design:LidPreview:3";
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Rectangle { objectName:"design:LidPreview:4";
                width: 40
                height: 24
                radius: Theme.radiusSmall - 4
                color: root.lit ? Theme.accentIn(QsWindow.window) : Theme.island
                border.color: Theme.borderIn(QsWindow.window)
                border.width: 1
                opacity: root.lit ? 1 : 0.8

                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                // The closed lid as a line across the screen; a side-on hinge
                // is unreadable at this size.
                Rectangle { objectName:"design:LidPreview:5";
                    anchors.centerIn: parent
                    width: parent.width - 10
                    height: 1
                    color: root.lit ? Theme.accentTextIn(QsWindow.window) : Theme.borderIn(QsWindow.window)
                    opacity: 0.7
                }
            }

            Rectangle { objectName:"design:LidPreview:6";
                width: 46
                height: 3
                radius: 1.5
                x: -3
                color: Theme.borderIn(QsWindow.window)
            }
        }

        // The monitor, always lit when present.
        Column { objectName:"design:LidPreview:7";
            anchors.verticalCenter: parent.verticalCenter
            visible: root.external
            spacing: 2

            Rectangle { objectName:"design:LidPreview:8";
                width: 44
                height: 28
                radius: Theme.radiusSmall - 4
                color: Theme.accentIn(QsWindow.window)
                border.color: Theme.borderIn(QsWindow.window)
                border.width: 1
            }

            Rectangle { objectName:"design:LidPreview:9";
                width: 14
                height: 3
                radius: 1.5
                x: 15
                color: Theme.borderIn(QsWindow.window)
            }
        }
    }
}
