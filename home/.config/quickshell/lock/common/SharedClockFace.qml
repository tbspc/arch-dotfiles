// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   L O C K   C L O C K                                                    │
// │   the lock's clock · stacked, inline or flip, the date above it          │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import QtQuick.Effects

// The date above, then the time: hours over minutes with the minutes softer,
// the two on one line, or each on a card that folds over when it changes.
// The login screen draws the stacked one to the same numbers. Shared with
// the setting's preview, which passes a fixed time.
Item {
    id: root

    // "stacked", "inline" or "flip".
    property var configuration: ({})
    property string style: configuration.lockClock ?? "inline"
    property date now: new Date()
    readonly property color ink: configuration.lockTextColor ?? "#ffffff"
    opacity: (configuration.lockClockOpacity ?? 100) / 100
    layer.enabled: (configuration.lockClockShadow ?? 45) > 0
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: 1
        shadowOpacity: (root.configuration.lockClockShadow ?? 45) / 100
        shadowVerticalOffset: 3
        shadowColor: "#000000"
    }

    // Empty follows the clock; the preview sets one.


    readonly property bool stacked: root.style !== "inline" && root.style !== "flip"
    readonly property bool flip: root.style === "flip"

    readonly property int dateSize: configuration.lockDateSize ?? 22
    readonly property int inlineSize: configuration.lockClockSize ?? 168
    readonly property string clockFont: configuration.lockFontFamily ?? "Nunito"
    readonly property int stackedSize: Math.round(root.inlineSize * 300 / 168)
    readonly property int flipSize: Math.round(root.inlineSize * 190 / 168)

    // A figure's cap height is about 0.73 of its size in Inter, and a line is
    // about 1.21: stacked lines overlap by the difference, less a gap.
    readonly property int stackedGap: 18

    // The clock's own format, split on its separator for the stacked form.
    readonly property string time: Qt.formatDateTime(root.now, root.configuration.lockTimeFormat ?? "HH:mm")
    readonly property var parts: root.time.split(":")

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight


    Column {
        id: column

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.stacked || root.flip ? root.stackedGap : -Math.round(root.inlineSize * 0.07)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.configuration.lockShowsDate ?? true
            text: Qt.formatDateTime(root.now, root.clockFont==="SF Pro Display"?"dddd, MMMM d":"ddd MMM d")
            font.family:root.configuration.lockDesign==="reference"?"SF Pro Display":root.clockFont==="SF Pro Display"?"SF Pro Text":root.clockFont
            font.pixelSize: root.dateSize
            font.weight:root.configuration.lockDesign==="reference"?Font.DemiBold:Font.Medium
            color: root.ink
            opacity: (root.configuration.lockDateOpacity ?? 78) / 100
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.flip
            spacing: Math.round(root.flipSize * 0.1)

            // By count, so a new minute folds the card already there
            // rather than building another.
            Repeater {
                model: root.flip ? root.parts.length : 0

                SharedFlipCard {
                    fontFamily: root.clockFont
                    ink: root.ink
                    motion: root.configuration.lockMotion ?? 1
                    required property int index

                    value: root.parts[index] ?? ""
                    size: root.flipSize
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !root.stacked && !root.flip
            text: root.time
            font.family: root.clockFont
            font.pixelSize: root.inlineSize
            font.weight: root.configuration.lockDesign==="reference"?Font.DemiBold:root.clockFont==="SF Pro Display"?Font.DemiBold:Font.Bold
            font.letterSpacing:root.configuration.lockDesign==="reference"?-root.inlineSize*6.5/146:-Math.round(root.inlineSize*.033)
            font.features:root.configuration.lockDesign==="reference"?({"pnum":1,"tnum":0}):({"tnum":1})
            color: root.ink
        }

        // The two lines overlap by their empty leading, so the figures sit a
        // gap apart rather than a line apart.
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.stacked
            spacing: -Math.round(root.stackedSize * 0.48) + root.stackedGap
            topPadding: -Math.round(root.stackedSize * 0.24)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.parts[0] ?? ""
                font.family: root.clockFont
                font.pixelSize: root.stackedSize
                font.weight: root.clockFont==="SF Pro Display"?Font.DemiBold:Font.Bold
                font.letterSpacing: -Math.round(root.stackedSize * 0.04)
                font.features: { "tnum": 1 }
                color: root.ink
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.parts.slice(1).join(":")
                font.family: root.clockFont
                font.pixelSize: root.stackedSize
                font.weight: root.clockFont==="SF Pro Display"?Font.DemiBold:Font.Bold
                font.letterSpacing: -Math.round(root.stackedSize * 0.04)
                font.features: { "tnum": 1 }
                color: root.ink
                opacity: 0.55
            }
        }
    }
}
