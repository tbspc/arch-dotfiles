// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   M E D I A   M O D U L E                                                │
// │   media · artwork and spectrum, full player when open                    │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts
import Quickshell.Widgets

import "../../theme"
import "../../services"
import "../../components"

// The chip announces playback: artwork and a spectrum. The detail is the
// player: artwork, title, artist, progress and transport.
//
// The spectrum comes from cava, so it follows the actual audio and stops on
// silence. It is white because colour on the bar signals a level.
Item { objectName:"design:MediaModule:1";
    id: root

    property bool compact: false

    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight

    Component.onCompleted: {
        MediaService.subscribe()
        CavaService.subscribe()
    }
    Component.onDestruction: {
        MediaService.release()
        CavaService.release()
    }

    function clock(seconds: real): string {
        const total = Math.max(0, Math.floor(seconds))
        const minutes = Math.floor(total / 60)
        const rest = total % 60
        return `${minutes}:${rest < 10 ? "0" : ""}${rest}`
    }

    Loader {
        id: holder
        anchors.fill: parent
        sourceComponent: root.compact ? chip : detail
    }

    // ── CHIP ────────────────────────────────────────────────────────────────

    // Ring face: the artwork as a disc inside a ring driven by loudness. The
    // title is the figure, drawn by `ChipFace`.
    Component {
        id: chip

        Item { objectName:"design:MediaModule:2";
            id: chipRoot

            readonly property real artSize: Math.round(Theme.capsuleHeight * 0.62)

            Item { objectName:"design:MediaModule:3";
                id: mark

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.capsuleHeight
                height: Theme.capsuleHeight

                RingIndicator {
                    anchors.fill: parent
                    thickness: 2.5
                    progress: MediaService.playing ? CavaService.level : 0
                    trackColor: Theme.indicatorDim
                    // White: loudness has no level worth colouring, unlike
                    // charge or a countdown.
                    fillColor: Theme.moduleColour("media","accent",Theme.indicator)
                    // Short enough to track the audio.
                    sweepDuration: 90
                }

                // ClippingRectangle, because `clip` is rectangular and would
                // square the artwork's corners.
                ClippingRectangle { objectName:"design:MediaModule:4";
                    anchors.centerIn: parent
                    width: chipRoot.artSize
                    height: chipRoot.artSize
                    radius: width / 2
                    // None behind a picture: a player may send its logo on transparency.
                    color: chipArt.visible ? "transparent" : Theme.surfaceHoverIn(QsWindow.window)

                    Image { objectName:"design:MediaModule:5";
                        id: chipArt
                        anchors.fill: parent
                        source: MediaService.artUrl
                        visible: source != "" && status === Image.Ready
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 44
                        sourceSize.height: 44
                    }

                    Text { objectName:"design:MediaModule:6";
                        anchors.centerIn: parent
                        visible: !chipArt.visible
                        text: "󰎇"
                        font.family: Theme.fontMono
                        font.pixelSize: Math.round(chipRoot.artSize * 0.55)
                        color: Theme.moduleColour("media","accent",Theme.indicator)
                    }
                }
            }
        }
    }

    // ── DETAIL ──────────────────────────────────────────────────────────────

    // The artwork is the mark, the track the heading; then progress, hidden
    // for streams, which have no length, and transport with the spectrum.
    Component {
        id: detail

        ModuleCard {
            // Opened, the player asks for the lyrics, and opens out round
            // them once they come (`DetailFace`).
            Component.onCompleted: LyricsService.subscribe()
            Component.onDestruction: LyricsService.release()

            title: MediaService.title !== "" ? MediaService.title : MediaService.identity
            subtitle: MediaService.artist !== "" ? MediaService.artist : MediaService.identity

            // ClippingRectangle, because `clip` is rectangular and would
            // square the artwork's corners.
            mark: ClippingRectangle {
                anchors.fill: parent
                radius: width * Theme.pictureCorner
                // None behind a picture: a player may send its logo on transparency.
                color: art.visible ? "transparent" : Theme.surfaceHoverIn(QsWindow.window)

                Image { objectName:"design:MediaModule:7";
                    id: art
                    anchors.fill: parent
                    source: MediaService.artUrl
                    visible: source != "" && status === Image.Ready
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 2 * Theme.cardMark
                    sourceSize.height: 2 * Theme.cardMark
                }

                Text { objectName:"design:MediaModule:8";
                    anchors.centerIn: parent
                    visible: !art.visible
                    text: "󰎇"
                    font.family: Theme.fontMono
                    font.pixelSize: 20
                    color: Theme.moduleColour("media","accent",Theme.indicator)
                }
            }

            // ── PROGRESS ────────────────────────────────────────────────────

            // The whole strip is the hit area; the handle appears on hover.
            Item { objectName:"design:MediaModule:9";
                id: seek

                Layout.fillWidth: true
                Layout.preferredHeight: Theme.cardRow
                visible: MediaService.seekable

                readonly property real trackLeft: elapsedLabel.width + 10
                readonly property real trackRight: seek.width - lengthLabel.width - 10
                readonly property real trackWidth: Math.max(1, seek.trackRight - seek.trackLeft)

                Text { objectName:"design:MediaModule:10";
                    id: elapsedLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.clock(MediaService.position)
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeLabel
                    color: Theme.moduleColour("media","muted",Theme.textMuted)
                }

                UsageBar {
                    id: track
                    x: seek.trackLeft
                    width: seek.trackWidth
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: seekMouse.containsMouse ? 6 : 4
                    progress: MediaService.progress
                    fillColor: Theme.moduleColour("media","accent",Theme.indicator)

                    Behavior on implicitHeight {
                        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
                    }
                }

                Rectangle { objectName:"design:MediaModule:11";
                    width: 10
                    height: 10
                    radius: 5
                    color: Theme.moduleColour("media","accent",Theme.indicator)
                    visible: MediaService.canSeek && seekMouse.containsMouse
                    x: track.x + track.width * Math.max(0, Math.min(1, MediaService.progress)) - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text { objectName:"design:MediaModule:12";
                    id: lengthLabel
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.clock(MediaService.length)
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeLabel
                    color: Theme.moduleColour("media","muted",Theme.textMuted)
                }

                MouseArea {
                    id: seekMouse

                    x: seek.trackLeft
                    width: seek.trackWidth
                    height: parent.height
                    hoverEnabled: true
                    enabled: MediaService.canSeek
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPressed: event => MediaService.seek(event.x / seek.trackWidth)
                    onPositionChanged: event => {
                        if (pressed)
                            MediaService.seek(event.x / seek.trackWidth)
                    }
                }
            }

            // ── TRANSPORT ───────────────────────────────────────────────────

            // Centred with anchors: spacers only centre when both sides are
            // equally wide. The spectrum sits on the right, out of their way.
            Item { objectName:"design:MediaModule:13";
                Layout.fillWidth: true
                Layout.preferredHeight: 34

                Row { objectName:"design:MediaModule:14";
                    anchors.centerIn: parent
                    spacing: 10

                    IconButton {
                        icon: "󰒮"
                        iconSize: 17
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: 17
                        enabled: MediaService.canPrevious
                        opacity: enabled ? 1 : 0.3
                        onClicked: MediaService.previous()
                    }

                    IconButton {
                        icon: MediaService.playing ? "󰏤" : "󰐊"
                        iconSize: 22
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: 17
                        onClicked: MediaService.toggle()
                    }

                    IconButton {
                        icon: "󰒭"
                        iconSize: 17
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: 17
                        enabled: MediaService.canNext
                        opacity: enabled ? 1 : 0.3
                        onClicked: MediaService.next()
                    }
                }

                Spectrum {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 18
                    barWidth: 3
                    minimum: 2
                    active: MediaService.playing
                    barColor: Theme.moduleColour("media","accent",Theme.indicator)
                }
            }
        }
    }
}
