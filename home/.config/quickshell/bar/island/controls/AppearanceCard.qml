// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   A P P E A R A N C E   C A R D                                          │
// │   current wallpaper · opens the appearance panel                         │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts
import Quickshell.Widgets

import "../../../theme"
import "../../../services"
import "../../../components"

// Shows the current wallpaper and opens the appearance panel.
// ClippingRectangle rather than `clip`, which is rectangular and would square
// the corners; `contentUnderBorder` keeps the outline over the picture.
ClippingRectangle { objectName:"design:AppearanceCard:1";
    id: root

    signal requested()

    contentUnderBorder: true
    radius: Theme.radiusMedium
    color: Theme.surfaceIn(QsWindow.window)
    border.color: mouse.containsMouse ? Theme.moduleColour("appearance","accent",Theme.accent) : Theme.borderIn(QsWindow.window)
    border.width: 1

    Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

    Image { objectName:"design:AppearanceCard:2";
        id: wallpaper
        anchors.fill: parent
        source: WallpaperService.currentWallpaper !== ""
            ? `file://${WallpaperService.currentWallpaper}` : ""
        visible: source != "" && status === Image.Ready
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 560
        sourceSize.height: 320
        scale: mouse.containsMouse ? 1.04 : 1

        Behavior on scale {
            NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
        }
    }

    // The label gets its own background, since it sits on a photograph.
    Rectangle { objectName:"design:AppearanceCard:3";
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 52
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.45; color: Theme.scrim }
            GradientStop { position: 1.0; color: Theme.island }
        }
    }

    RowLayout { objectName:"design:AppearanceCard:4";
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        spacing: 10

        ColorSwatch {
            Layout.alignment: Qt.AlignVCenter
            swatchSize: 11
            colors: ThemeService.activeId === "adaptive"
                ? ThemeService.adaptiveSwatches
                : (Palettes.byId(ThemeService.activeId)?.swatches ?? ThemeService.adaptiveSwatches)
        }

        ColumnLayout { objectName:"design:AppearanceCard:5";
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text { objectName:"design:AppearanceCard:6";
                Layout.fillWidth: true
                text: "Appearance"
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                color: Theme.scrimText
            }

            Text { objectName:"design:AppearanceCard:7";
                Layout.fillWidth: true
                text: Theme.activeName
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
                color: Theme.scrimText
                opacity: 0.7
            }
        }

        Text { objectName:"design:AppearanceCard:8";
            Layout.alignment: Qt.AlignVCenter
            text: "󰅂"
            font.family: Theme.fontMono
            font.pixelSize: 14
            color: mouse.containsMouse ? Theme.moduleColour("appearance","accent",Theme.accent) : Theme.scrimText
            opacity: mouse.containsMouse ? 1 : 0.7

            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.requested()
    }
}
