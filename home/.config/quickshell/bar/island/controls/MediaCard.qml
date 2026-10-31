// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   M E D I A   C A R D                                                    │
// │   the player, with room for artwork and transport                        │
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

Card {
    id: root

    Component.onCompleted: MediaService.subscribe()
    Component.onDestruction: MediaService.release()

    Text { objectName:"design:MediaCard:1";
        anchors.centerIn: parent
        visible: !MediaService.available
        text: "Nothing playing"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.moduleColour("media","muted",Theme.textMuted)
    }

    ColumnLayout { objectName:"design:MediaCard:2";
        anchors.fill: parent
        visible: MediaService.available
        spacing: 11

        RowLayout { objectName:"design:MediaCard:3";
            Layout.fillWidth: true
            spacing: 12

            ClippingRectangle { objectName:"design:MediaCard:4";
                Layout.preferredWidth: 58
                Layout.preferredHeight: 58
                radius: width * Theme.pictureCorner
                // None behind a picture: a player may send its logo on transparency.
                color: art.visible ? "transparent" : Theme.surfaceHoverIn(QsWindow.window)

                Image { objectName:"design:MediaCard:5";
                    id: art
                    anchors.fill: parent
                    source: MediaService.artUrl
                    visible: source != "" && status === Image.Ready
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 116
                    sourceSize.height: 116
                }

                Text { objectName:"design:MediaCard:6";
                    anchors.centerIn: parent
                    visible: !art.visible
                    text: "󰎇"
                    font.family: Theme.fontMono
                    font.pixelSize: 22
                    color: Theme.moduleColour("media","accent",Theme.accent)
                }
            }

            ColumnLayout { objectName:"design:MediaCard:7";
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text { objectName:"design:MediaCard:8";
                    Layout.fillWidth: true
                    text: MediaService.title
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeRegular
                    font.weight: Font.DemiBold
                    color: Theme.moduleColour("media","foreground",Theme.text)
                }

                Text { objectName:"design:MediaCard:9";
                    Layout.fillWidth: true
                    text: MediaService.artist
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.moduleColour("media","muted",Theme.textMuted)
                }
            }
        }

        Item { objectName:"design:MediaCard:10"; Layout.fillHeight: true }

        // Progress, only when the track has a length.
        Rectangle { objectName:"design:MediaCard:11";
            Layout.fillWidth: true
            Layout.preferredHeight: 3
            visible: MediaService.seekable
            radius: 1.5
            color: Theme.surfaceHoverIn(QsWindow.window)

            Rectangle { objectName:"design:MediaCard:12";
                width: parent.width * MediaService.progress
                height: parent.height
                radius: parent.radius
                color: Theme.moduleColour("media","accent",Theme.accent)

                Behavior on width {
                    NumberAnimation { duration: 900; easing.type: Easing.Linear }
                }
            }
        }

        RowLayout { objectName:"design:MediaCard:13";
            Layout.fillWidth: true
            spacing: 6

            Text { objectName:"design:MediaCard:14";
                text: root.clock(MediaService.position)
                visible: MediaService.seekable
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeLabel
                color: Theme.moduleColour("media","muted",Theme.textMuted)
            }

            Item { objectName:"design:MediaCard:15"; Layout.fillWidth: true }

            IconButton {
                icon: "󰒮"
                iconSize: 15
                enabled: MediaService.canPrevious
                opacity: MediaService.canPrevious ? 1 : 0.35
                onClicked: MediaService.previous()
            }

            IconButton {
                icon: MediaService.playing ? "󰏤" : "󰐊"
                iconSize: 18
                onClicked: MediaService.toggle()
            }

            IconButton {
                icon: "󰒭"
                iconSize: 15
                enabled: MediaService.canNext
                opacity: MediaService.canNext ? 1 : 0.35
                onClicked: MediaService.next()
            }

            Item { objectName:"design:MediaCard:16"; Layout.fillWidth: true }

            Text { objectName:"design:MediaCard:17";
                text: root.clock(MediaService.length)
                visible: MediaService.seekable
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeLabel
                color: Theme.moduleColour("media","muted",Theme.textMuted)
            }
        }
    }

    function clock(seconds: real): string {
        const total = Math.max(0, Math.floor(seconds))
        const minutes = Math.floor(total / 60)
        const remainder = total % 60
        return `${minutes}:${remainder < 10 ? "0" : ""}${remainder}`
    }
}
