// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   M O D U L E   C A R D                                                  │
// │   a module's detail · its heading on a mark, then its rows               │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../theme"

// Every module's detail is one of these, so they share their margins, their
// heading and the height of their rows (`Theme.card*`), and a card's height is
// `Theme.cardHeight` of what it holds. The mark is whatever the module draws
// itself as, in a `Theme.cardMark` box; the rows go in as children.
ColumnLayout { objectName:"design:ModuleCard:1";
    id: root

    property alias mark: markSlot.data
    property string title: ""
    property string subtitle: ""
    // A figure on the right of the heading, for the one number the card is
    // about.
    property string figure: ""
    property color figureColor: Theme.textIn(QsWindow.window)

    default property alias rows: body.data

    anchors.fill: parent
    anchors.margins: Theme.cardPadding
    spacing: Theme.cardGap

    RowLayout { objectName:"design:ModuleCard:2";
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.cardMark
        spacing: 12

        Item { objectName:"design:ModuleCard:3";
            id: markSlot

            Layout.preferredWidth: Theme.cardMark
            Layout.preferredHeight: Theme.cardMark
        }

        ColumnLayout { objectName:"design:ModuleCard:4";
            Layout.fillWidth: true
            spacing: 2

            Text { objectName:"design:ModuleCard:5";
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                font.family: Theme.fontIn(QsWindow.window)
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                color: Theme.textIn(QsWindow.window)
            }

            Text { objectName:"design:ModuleCard:6";
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                elide: Text.ElideRight
                font.family: Theme.fontIn(QsWindow.window)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.mutedIn(QsWindow.window)
            }
        }

        Text { objectName:"design:ModuleCard:7";
            visible: root.figure !== ""
            text: root.figure
            font.family: Theme.fontIn(QsWindow.window)
            font.pixelSize: Theme.cardFigure
            font.weight: Font.DemiBold
            color: root.figureColor
        }
    }

    ColumnLayout { objectName:"design:ModuleCard:8";
        id: body

        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: children.length > 0
        spacing: Theme.cardRowGap
    }
}
