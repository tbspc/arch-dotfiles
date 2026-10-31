// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S T A T S   P A N E L                                                  │
// │   system statistics · load, memory and history                           │
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

// Each card pairs a figure with its recent history. Weighted rather than
// evenly tiled: the processor gets the most room, storage a corner.
ColumnLayout { objectName:"design:StatsPanel:1";
    id: root

    signal closed()

    readonly property int gap: 12

    spacing: root.gap

    // ── BODY ────────────────────────────────────────────────────────────────

    RowLayout { objectName:"design:StatsPanel:2";
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: root.gap

        ColumnLayout { objectName:"design:StatsPanel:3";
            // Wider: the two readings that change while you watch.
            Layout.preferredWidth: 3
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.gap

            StatCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 5
                Layout.fillHeight: true
                icon: "󰻠"
                title: "Processor"
                reading: `${StatsService.cpu.toFixed(0)}%`
                detail: `load ${StatsService.load[0].toFixed(2)}  ·  ${StatsService.cores.length} threads`
                    + `  ·  up ${StatsService.duration(StatsService.uptime)}`
                series: StatsService.cpuHistory
                accent: Theme.moduleColour("stats","accent",Theme.accent)

                // Per core, because an average hides a single pinned core.
                RowLayout { objectName:"design:StatsPanel:4";
                    Layout.fillWidth: true
                    spacing: 3

                    Repeater {
                        model: ScriptModel {
                            values: StatsService.cores
                        }

                        Rectangle { objectName:"design:StatsPanel:5";
                            required property real modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            radius: 2
                            color: Theme.surfaceHoverIn(QsWindow.window)

                            Rectangle { objectName:"design:StatsPanel:6";
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: Math.max(2, parent.height * Math.min(1, modelData / 100))
                                radius: 2
                                color: modelData > 80 ? Theme.red : Theme.moduleColour("stats","accent",Theme.accent)

                                Behavior on height {
                                    NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
                                }
                                Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                            }
                        }
                    }
                }
            }

            StatCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                Layout.fillHeight: true
                icon: "󰍛"
                title: "Memory"
                reading: `${(StatsService.memoryFraction * 100).toFixed(0)}%`
                detail: `${StatsService.bytes(StatsService.memoryUsed)} of ${StatsService.bytes(StatsService.memoryTotal)}`
                series: StatsService.memoryHistory
                accent: Theme.blue

                RowLayout { objectName:"design:StatsPanel:7";
                    Layout.fillWidth: true
                    spacing: 8
                    visible: StatsService.swapTotal > 0

                    Text { objectName:"design:StatsPanel:8";
                        text: "SWAP"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        color: Theme.moduleColour("stats","muted",Theme.textMuted)
                    }

                    Rectangle { objectName:"design:StatsPanel:9";
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        Layout.alignment: Qt.AlignVCenter
                        radius: 2
                        color: Theme.surfaceHoverIn(QsWindow.window)

                        Rectangle { objectName:"design:StatsPanel:10";
                            width: parent.width * StatsService.swapFraction
                            height: parent.height
                            radius: 2
                            color: Theme.yellow

                            Behavior on width {
                                NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
                            }
                        }
                    }

                    Text { objectName:"design:StatsPanel:11";
                        text: StatsService.bytes(StatsService.swapUsed)
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.moduleColour("stats","muted",Theme.textMuted)
                    }
                }
            }
        }

        ColumnLayout { objectName:"design:StatsPanel:12";
            Layout.preferredWidth: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.gap

            StatCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: StatsService.temperature !== null
                icon: "󰔏"
                title: "Temperature"
                reading: StatsService.temperature ? `${StatsService.temperature.celsius}°` : "—"
                detail: StatsService.temperature
                    ? `${StatsService.thermalWord}  ·  ${StatsService.temperature.label}` : ""
                // Degrees have no natural ceiling worth drawing against, so the
                // line scales to the range actually seen.
                maximum: 0
                series: StatsService.temperatureHistory
                accent: StatsService.temperature && StatsService.temperature.celsius > 80
                    ? Theme.red : Theme.yellow
            }

            StatCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "󰛳"
                title: "Network"
                reading: StatsService.rate(StatsService.networkDown)
                detail: `↑ ${StatsService.rate(StatsService.networkUp)}`
                maximum: 0
                series: StatsService.downHistory
                accent: Theme.green

                // Upload on the same axis as download, so the shape of a
                // transfer is visible rather than split across two cards.
                Sparkline {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    values: StatsService.upHistory
                    maximum: 0
                    stroke: Theme.blue
                    thickness: 1.2
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                padding: 14

                ColumnLayout { objectName:"design:StatsPanel:13";
                    anchors.fill: parent
                    spacing: 8

                    RowLayout { objectName:"design:StatsPanel:14";
                        Layout.fillWidth: true
                        spacing: 9

                        Text { objectName:"design:StatsPanel:15";
                            text: "󰋊"
                            font.family: Theme.fontMono
                            font.pixelSize: 15
                            color: Theme.moduleColour("stats","accent",Theme.accent)
                        }

                        Text { objectName:"design:StatsPanel:16";
                            text: "Storage"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.DemiBold
                            color: Theme.moduleColour("stats","foreground",Theme.text)
                        }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: StatsService.disks
                        }

                        ColumnLayout { objectName:"design:StatsPanel:17";
                            id: disk

                            required property var modelData
                            readonly property real fraction:
                                disk.modelData.total > 0 ? disk.modelData.used / disk.modelData.total : 0

                            Layout.fillWidth: true
                            spacing: 3

                            RowLayout { objectName:"design:StatsPanel:18";
                                Layout.fillWidth: true

                                Text { objectName:"design:StatsPanel:19";
                                    text: disk.modelData.target
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fontSizeLabel
                                    color: Theme.moduleColour("stats","foreground",Theme.text)
                                }

                                Item { objectName:"design:StatsPanel:20"; Layout.fillWidth: true }

                                // Free space, not used: how much room is left.
                                Text { objectName:"design:StatsPanel:21";
                                    text: `${StatsService.bytes(disk.modelData.total - disk.modelData.used)} free`
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: Theme.moduleColour("stats","muted",Theme.textMuted)
                                }
                            }

                            Rectangle { objectName:"design:StatsPanel:22";
                                Layout.fillWidth: true
                                Layout.preferredHeight: 5
                                radius: 2.5
                                color: Theme.surfaceHoverIn(QsWindow.window)

                                Rectangle { objectName:"design:StatsPanel:23";
                                    width: parent.width * disk.fraction
                                    height: parent.height
                                    radius: parent.radius
                                    // Warn above 90%.
                                    color: disk.fraction > 0.9 ? Theme.red
                                        : (disk.fraction > 0.75 ? Theme.yellow : Theme.moduleColour("stats","accent",Theme.accent))

                                    Behavior on width {
                                        NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
                                    }
                                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                                }
                            }
                        }
                    }

                    Item { objectName:"design:StatsPanel:24"; Layout.fillHeight: true }
                }
            }
        }
    }
}
