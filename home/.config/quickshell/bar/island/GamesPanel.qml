// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   G A M E S   P A N E L                                                  │
// │   arcade · the game shelf and the running game                           │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../../theme"
import "../../services"
import "../../components"
import "./games"

// The arcade: a shelf of cards (the appearance panel's strip, one game per
// tile; Left and Right slide, Enter plays). Opening a game morphs the island
// to that game's size. Escape goes back to the shelf, then closes.
//
// The frame around each game lives here: score and best, the game-over
// overlay, and R to restart. The games themselves know nothing about bests.
FocusScope {
    id: root

    signal closed()

    readonly property string playing: GamesService.playing
    readonly property var game: GamesService.entry(root.playing)

    // Focus on open, or the arrows go to whatever had the keyboard before.
    Component.onCompleted: root.forceActiveFocus()

    // Closing the panel leaves the game, so it reopens on the shelf.
    Component.onDestruction: GamesService.leave()

    Keys.onEscapePressed: event => {
        if (root.playing === "") {
            event.accepted = false
            return
        }
        GamesService.leave()
    }

    Loader {
        anchors.fill: parent
        focus: true
        sourceComponent: root.playing === "" ? shelf : frame
    }

    // ── SHELF ───────────────────────────────────────────────────────────────

    Component {
        id: shelf

        Item { objectName:"design:GamesPanel:1";
            id: page

            readonly property var chosen: GamesService.catalogue[strip.current] ?? null

            // The game last opened. An initial value for `current` rather than
            // a later call, so the shelf opens there instead of sliding from
            // the first tile.
            readonly property int opening: Math.max(0, GamesService.catalogue.findIndex(
                item => item.id === GamesService.lastOpened))

            // Explicit: `focus: true` down the chain does not reach an item
            // inside a Loader.
            Component.onCompleted: page.forceActiveFocus()

            function play(): void {
                if (page.chosen)
                    GamesService.open(page.chosen.id)
            }

            Keys.onLeftPressed: strip.step(-1)
            Keys.onRightPressed: strip.step(1)
            Keys.onReturnPressed: page.play()
            Keys.onEnterPressed: page.play()
            Keys.onSpacePressed: page.play()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Home)
                    strip.goTo(0)
                else if (event.key === Qt.Key_End)
                    strip.goTo(strip.count - 1)
                else
                    return
                event.accepted = true
            }

            ColumnLayout { objectName:"design:GamesPanel:2";
                anchors.fill: parent
                spacing: GamesService.stripGap

                Carousel {
                    id: strip

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    current: page.opening
                    model: GamesService.catalogue
                    onActivated: page.play()

                    delegate: CarouselTile {
                        id: card

                        readonly property color tint: GamesService.tintOf(card.modelData.id)

                        Rectangle { objectName:"design:GamesPanel:3";
                            anchors.fill: parent
                            radius: Theme.radiusMedium
                            color: card.hovered ? Theme.surfaceHoverIn(QsWindow.window) : Theme.surfaceIn(QsWindow.window)
                            // Ringed in the game's own tint, which its board
                            // also uses.
                            border.color: card.centred ? card.tint : Theme.borderIn(QsWindow.window)
                            border.width: card.centred ? 2 : 1

                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                            Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

                            Column { objectName:"design:GamesPanel:4";
                                anchors.centerIn: parent
                                spacing: 8

                                // The glyph on a tile of its own colour, like
                                // a launcher icon: the tint at a fifth, the
                                // glyph at full.
                                Rectangle { objectName:"design:GamesPanel:5";
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 44
                                    height: 44
                                    radius: 11
                                    color: Qt.rgba(card.tint.r, card.tint.g, card.tint.b, 0.2)

                                    Text { objectName:"design:GamesPanel:6";
                                        anchors.centerIn: parent
                                        text: card.modelData.icon
                                        font.family: Theme.fontMono
                                        font.pixelSize: 22
                                        color: card.tint
                                    }
                                }

                                Text { objectName:"design:GamesPanel:7";
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: card.modelData.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: card.centred ? Font.DemiBold : Font.Normal
                                    color: card.centred ? Theme.moduleColour("games","foreground",Theme.text) : Theme.moduleColour("games","muted",Theme.textMuted)
                                }
                            }
                        }
                    }
                }

                // The middle game's best, and where in the shelf it is.
                RowLayout { objectName:"design:GamesPanel:8";
                    Layout.fillWidth: true
                    spacing: GamesService.stripGap

                    Text { objectName:"design:GamesPanel:9";
                        Layout.fillWidth: true
                        text: !page.chosen ? ""
                            : GamesService.played(page.chosen.id)
                                ? `Best ${GamesService.bestOf(page.chosen.id)}`
                                : "Not played yet"
                        elide: Text.ElideRight
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.moduleColour("games","muted",Theme.textMuted)
                    }

                    Text { objectName:"design:GamesPanel:10";
                        text: strip.count === 0 ? "" : `${strip.current + 1}/${strip.count}`
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.moduleColour("games","muted",Theme.textMuted)
                    }
                }
            }
        }
    }

    // ── FRAME ───────────────────────────────────────────────────────────────

    Component {
        id: frame

        ColumnLayout { objectName:"design:GamesPanel:11";
            id: round

            // Whether the round that just ended beat the best. Set from the
            // record, and cleared on restart.
            property bool beaten: false

            readonly property var played: board.game
            readonly property bool over: round.played ? round.played.over : false
            readonly property int score: round.played ? round.played.score : 0
            readonly property bool byMoves: root.game ? root.game.lower : false

            spacing: GamesService.stripGap

            function again(): void {
                round.beaten = false
                if (round.played)
                    round.played.restart()
            }

            // R restarts at any time. Enter and Space do too once the round
            // is over; while it runs they belong to the game. No game uses R.
            Keys.onPressed: event => {
                const again = event.key === Qt.Key_R
                    || (round.over && (event.key === Qt.Key_Return
                        || event.key === Qt.Key_Enter || event.key === Qt.Key_Space))
                if (!again)
                    return
                round.again()
                event.accepted = true
            }

            Connections {
                target: round.played

                function onFinished(score: int): void {
                    round.beaten = GamesService.record(root.playing, score)
                }
            }

            RowLayout { objectName:"design:GamesPanel:12";
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: GamesService.stripHeight
                spacing: 10

                // Just the score and the best: no name, no key hints, and no
                // buttons for what a key already does.
                Item { objectName:"design:GamesPanel:13"; Layout.fillWidth: true }

                // The score beats when it changes, so every game has one
                // piece of feedback the frame gives it for free.
                Text { objectName:"design:GamesPanel:14";
                    id: tally

                    text: `${round.byMoves ? "Moves" : "Score"} ${round.score}`
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.moduleColour("games","foreground",Theme.text)

                    Connections {
                        target: round

                        function onScoreChanged(): void {
                            if (round.score !== 0)
                                beat.restart()
                        }
                    }

                    NumberAnimation {
                        id: beat

                        target: tally
                        property: "scale"
                        from: 1.22
                        to: 1
                        duration: 220
                        easing.type: Easing.OutBack
                    }
                }

                Text { objectName:"design:GamesPanel:15";
                    visible: GamesService.played(root.playing)
                    text: `Best ${GamesService.bestOf(root.playing)}`
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.moduleColour("games","muted",Theme.textMuted)
                }
            }

            Item { objectName:"design:GamesPanel:16";
                Layout.fillWidth: true
                Layout.fillHeight: true

                GameBoard {
                    id: board

                    anchors.fill: parent
                    gameId: root.playing
                    tint: GamesService.tintOf(root.playing)
                }

                // Over the board once the round ends; the board stays visible
                // beneath it.
                Rectangle { objectName:"design:GamesPanel:17";
                    anchors.fill: parent
                    visible: opacity > 0
                    opacity: round.over ? 1 : 0
                    radius: Theme.radiusMedium
                    color: Theme.scrim

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
                    }

                    // A beaten best throws a ring behind the card.
                    Burst {
                        id: fanfare

                        anchors.centerIn: parent
                        tint: Theme.indicatorWarn
                        spread: 120
                        sparks: 10
                        span: 620
                    }

                    // `parent` inside a Connections is the Burst's parent, not
                    // the Burst, so the ring is played by name.
                    Connections {
                        target: round

                        function onBeatenChanged(): void {
                            if (round.beaten)
                                fanfare.play()
                        }
                    }

                    // The end of the round on a card of its own, which lands
                    // rather than appears.
                    Rectangle { objectName:"design:GamesPanel:18";
                        id: card

                        anchors.centerIn: parent
                        width: ending.implicitWidth + 56
                        height: ending.implicitHeight + 36
                        radius: Theme.radiusLarge
                        color: Theme.surfaceIn(QsWindow.window)
                        border.color: round.beaten ? Theme.indicatorWarn : Theme.borderIn(QsWindow.window)
                        border.width: 1
                        scale: round.over ? 1 : 0.92

                        Behavior on scale {
                            NumberAnimation { duration: 260; easing.type: Easing.OutBack }
                        }

                        Column { objectName:"design:GamesPanel:19";
                            id: ending

                            anchors.centerIn: parent
                            spacing: 10

                            Text { objectName:"design:GamesPanel:20";
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: round.byMoves ? "Solved" : "Game over"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.DemiBold
                                color: Theme.moduleColour("games","foreground",Theme.text)
                            }

                            Text { objectName:"design:GamesPanel:21";
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: round.beaten
                                    ? `★ New best · ${round.score}`
                                    : `${round.byMoves ? "Moves" : "Score"} ${round.score}`
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeMedium
                                color: round.beaten ? Theme.indicatorWarn : Theme.moduleColour("games","muted",Theme.textMuted)
                            }

                            PillButton {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Play again"
                                active: true
                                onClicked: round.again()
                            }
                        }
                    }

                    // A click on the wash is the same as the button.
                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: round.again()
                    }
                }
            }
        }
    }
}
