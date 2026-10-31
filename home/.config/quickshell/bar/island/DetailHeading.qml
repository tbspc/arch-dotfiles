// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   D E T A I L   H E A D I N G                                            │
// │   a control-centre page's title · back, name and what it is set to       │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts

import "../../theme"
import "../../components"

// The top of a page the control centre opens into: the way back, the page's
// name, and under it what it is set to now.
RowLayout { objectName:"design:DetailHeading:1";
    id: root

    property string title: ""
    property string detail: ""

    signal back()

    Layout.fillWidth: true
    Layout.preferredHeight: Theme.detailHeader
    spacing: 10

    IconButton {
        icon: "󰅁"
        iconSize: 14
        onClicked: root.back()
    }

    ColumnLayout { objectName:"design:DetailHeading:2";
        spacing: 1

        Text { objectName:"design:DetailHeading:3";
            text: root.title
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
            color: Theme.moduleColour("_shared","foreground",Theme.text)
        }

        Text { objectName:"design:DetailHeading:4";
            visible: text !== ""
            text: root.detail
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLabel
            color: Theme.moduleColour("_shared","muted",Theme.textMuted)
        }
    }

    Item { objectName:"design:DetailHeading:5"; Layout.fillWidth: true }
}
