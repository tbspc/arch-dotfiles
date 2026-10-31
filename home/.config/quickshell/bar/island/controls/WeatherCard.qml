// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   W E A T H E R   C A R D                                                │
// │   weather · now and the rest of the day                                  │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../../theme"
import "../../../services"
import "../../../components"

// Current conditions and the next few hours from wttr.in, which geolocates by
// IP, so the location is shown as part of the reading.
//
// One row: a single line. Two rows: now. Three: the rest of the day below it.
// Four columns: the two side by side.
Card {
    id: root

    property int cols: 2
    property int rows: 3

    readonly property bool oneLine: root.rows <= 1
    readonly property bool beside: root.cols >= 4 && root.rows <= 2
    readonly property bool showAhead: !root.oneLine && (root.rows >= 3 || root.beside)

    Component.onCompleted: WeatherService.subscribe()
    Component.onDestruction: WeatherService.release()

    // ── LINE ────────────────────────────────────────────────────────────────

    RowLayout { objectName:"design:WeatherCard:1";
        anchors.fill: parent
        visible: root.oneLine
        spacing: 10

        Text { objectName:"design:WeatherCard:2";
            text: WeatherService.available ? WeatherService.glyph : "󰅤"
            font.family: Theme.fontMono
            font.pixelSize: 22
            color: Theme.moduleColour("weather","accent",Theme.accent)
        }

        Text { objectName:"design:WeatherCard:3";
            text: WeatherService.available ? `${WeatherService.temperature}°` : "—"
            font.family: Theme.fontFamily
            font.pixelSize: 20
            font.weight: Font.DemiBold
            color: Theme.moduleColour("weather","foreground",Theme.text)
        }

        Text { objectName:"design:WeatherCard:4";
            Layout.fillWidth: true
            text: WeatherService.available
                ? `${WeatherService.description}  ·  feels ${WeatherService.feelsLike}°`
                : "No reading"
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.moduleColour("weather","muted",Theme.textMuted)
        }

        Text { objectName:"design:WeatherCard:5";
            visible: WeatherService.available
            text: `${WeatherService.high}° / ${WeatherService.low}°`
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeLabel
            color: Theme.moduleColour("weather","muted",Theme.textMuted)
        }
    }

    // ── CARD ────────────────────────────────────────────────────────────────

    GridLayout { objectName:"design:WeatherCard:6";
        anchors.fill: parent
        visible: !root.oneLine
        columns: root.beside ? 2 : 1
        rowSpacing: 10
        columnSpacing: 16

        // ── NOW ─────────────────────────────────────────────────────────────

        RowLayout { objectName:"design:WeatherCard:7";
            Layout.fillWidth: true
            // Side by side, equal preferred widths so the two halves split the
            // card evenly.
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Text { objectName:"design:WeatherCard:8";
                text: WeatherService.available ? WeatherService.glyph : "󰅤"
                font.family: Theme.fontMono
                font.pixelSize: 40
                color: Theme.moduleColour("weather","accent",Theme.accent)
            }

            ColumnLayout { objectName:"design:WeatherCard:9";
                Layout.fillWidth: true
                spacing: 1

                RowLayout { objectName:"design:WeatherCard:10";
                    Layout.fillWidth: true
                    spacing: 8

                    Text { objectName:"design:WeatherCard:11";
                        text: WeatherService.available
                            ? `${WeatherService.temperature}°`
                            : "—"
                        font.family: Theme.fontFamily
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                        color: Theme.moduleColour("weather","foreground",Theme.text)
                    }

                    // Pushed to the far edge.
                    Item { objectName:"design:WeatherCard:12"; Layout.fillWidth: true }

                    Text { objectName:"design:WeatherCard:13";
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 5
                        visible: WeatherService.available
                        text: `${WeatherService.high}° / ${WeatherService.low}°`
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeLabel
                        color: Theme.moduleColour("weather","muted",Theme.textMuted)
                    }
                }

                Text { objectName:"design:WeatherCard:14";
                    Layout.fillWidth: true
                    text: WeatherService.available
                        ? `${WeatherService.description}  ·  feels ${WeatherService.feelsLike}°`
                        : "No reading"
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.moduleColour("weather","muted",Theme.textMuted)
                }

                // Location and age share the line under the conditions to save
                // a row for the calendar in the same column.
                Text { objectName:"design:WeatherCard:15";
                    Layout.fillWidth: true
                    visible: WeatherService.available
                    text: `󰍎 ${WeatherService.place}, ${WeatherService.region}`
                        + `  ·  ${WeatherService.age}`
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLabel
                    color: Theme.moduleColour("weather","muted",Theme.textMuted)
                    opacity: 0.75
                }
            }
        }

        // Only when stacked: keeps the hours at the bottom of the card.
        Item { objectName:"design:WeatherCard:16";
            Layout.fillHeight: true
            visible: !root.beside
        }

        // ── REST OF THE DAY ─────────────────────────────────────────────────

        RowLayout { objectName:"design:WeatherCard:17";
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: root.beside ? Qt.AlignVCenter : Qt.AlignBottom
            spacing: 6
            visible: root.showAhead && WeatherService.ahead.length > 0

            Repeater {
                model: ScriptModel {
                    values: WeatherService.ahead
                }

                // A filling Item holding a centred Column: `Layout.fillWidth`
                // and `Layout.alignment` on the same item conflict, since an
                // alignment stops the layout from resizing it.
                Item { objectName:"design:WeatherCard:18";
                    id: block

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: stack.implicitHeight

                    Column { objectName:"design:WeatherCard:19";
                        id: stack

                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 3

                        Text { objectName:"design:WeatherCard:20";
                            anchors.horizontalCenter: parent.horizontalCenter
                            // Marks hours past midnight, so 21, 0, 3, 6 doesn't
                            // read as a broken sort.
                            text: {
                                const hour = `${block.modelData.hour}`.padStart(2, "0")
                                return block.modelData.tomorrow ? `${hour}:00⁺` : `${hour}:00`
                            }
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeLabel
                            color: Theme.moduleColour("weather","muted",Theme.textMuted)
                        }

                        Text { objectName:"design:WeatherCard:21";
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: block.modelData.glyph
                            font.family: Theme.fontMono
                            font.pixelSize: 16
                            color: Theme.moduleColour("weather","foreground",Theme.text)
                        }

                        Text { objectName:"design:WeatherCard:22";
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: `${block.modelData.temperature}°`
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.DemiBold
                            color: Theme.moduleColour("weather","foreground",Theme.text)
                        }

                        // Only when there is some chance of rain.
                        Text { objectName:"design:WeatherCard:23";
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: block.modelData.rain >= 20
                            text: `${block.modelData.rain}%`
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeLabel
                            color: Theme.blue
                        }
                    }
                }
            }
        }
    }
}
