// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   W E A T H E R   M O D U L E                                            │
// │   weather · condition icon, hourly forecast when open                    │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../theme"
import "../../services"
import "../../components"

// Condition glyph and temperature on the chip; the detail adds the location,
// feels-like and the next hours. Shows the reading's age, since it comes from
// the network.
Item { objectName:"design:WeatherModule:1";
    id: root

    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight

    Component.onCompleted: WeatherService.subscribe()
    Component.onDestruction: WeatherService.release()

    // Six hours rather than the card's four: this detail is wider.
    readonly property var hoursAhead: {
        const hour = WeatherService.clock.date.getHours()
        return (WeatherService.hourly ?? [])
            .filter(block => block.tomorrow || block.hour > hour)
            .slice(0, 6)
    }

    Loader {
        id: holder
        anchors.fill: parent
        sourceComponent: detail
    }

    // The condition is the mark and the temperature the figure; under them,
    // the next hours.
    Component {
        id: detail

        ModuleCard {
            title: WeatherService.place
            subtitle: {
                const parts = []
                if (WeatherService.description !== "")
                    parts.push(WeatherService.description)
                parts.push(`feels ${WeatherService.feelsLike}°`)
                if (WeatherService.age !== "")
                    parts.push(WeatherService.age)
                return parts.join(" · ")
            }
            figure: `${WeatherService.temperature}°`

            mark: Text {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: WeatherService.glyph
                font.family: Theme.fontMono
                font.pixelSize: 30
                color: Theme.moduleColour("weather","accent",Theme.indicator)
            }

            // Columns divide the width by hand: a RowLayout sizes from its
            // children's implicit widths and packs them to the left.
            Row { objectName:"design:WeatherModule:2";
                Layout.fillWidth: true
                Layout.preferredHeight: 50

                Repeater {
                    model: ScriptModel {
                        values: root.hoursAhead
                    }

                    Item { objectName:"design:WeatherModule:3";
                        id: block

                        required property var modelData

                        width: parent.width / Math.max(1, root.hoursAhead.length)
                        height: parent.height

                        Column { objectName:"design:WeatherModule:4";
                            anchors.centerIn: parent
                            spacing: 1

                            Text { objectName:"design:WeatherModule:5";
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: {
                                    const hour = `${block.modelData.hour}`.padStart(2, "0")
                                    return block.modelData.tomorrow
                                        ? `${hour}:00⁺` : `${hour}:00`
                                }
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeLabel
                                color: Theme.moduleColour("weather","muted",Theme.textMuted)
                            }

                            Text { objectName:"design:WeatherModule:6";
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: block.modelData.glyph
                                font.family: Theme.fontMono
                                font.pixelSize: 15
                                color: Theme.moduleColour("weather","accent",Theme.indicator)
                            }

                            Text { objectName:"design:WeatherModule:7";
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: `${block.modelData.temperature}°`
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeLabel
                                color: Theme.moduleColour("weather","foreground",Theme.text)
                            }
                        }
                    }
                }
            }
        }
    }
}
