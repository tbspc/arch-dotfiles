// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   I M P A S T O   B L O C K                                              │
// │   signature block · palette board and machine summary                    │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts

import "../../../theme"
import "../../../services"
import "../../../components"

// The terminal greeting as a block: the palette board where fastfetch puts its
// logo, and the same lines beside it (user@host, distribution, kernel,
// compositor, load, uptime, colour daubs). Static data from `MachineService`,
// live data from `StatsService`; the keys match `fastfetch/config.jsonc`.
// Not clickable.
//
// Small square: board, title and uptime. Wide: board beside the machine
// column. Large square: the full greeting, with the wordmark under the board.
Card {
    id: root

    property int cols: 1
    property int rows: 2

    readonly property bool tall: root.rows >= 4
    readonly property bool wide: root.cols >= 2 && !root.tall

    // The greeting's own size on the two smaller faces; one step up on the
    // large square.
    readonly property int type: root.tall ? Theme.fontSizeSmall : Theme.fontSizeLabel

    readonly property var disk: StatsService.disks.length > 0 ? StatsService.disks[0] : null

    // Tokens named explicitly (`Theme[key]` isn't a binding the engine tracks),
    // in the greeting's order: accent, then the four status hues.
    readonly property var paints: ({
        accent: Theme.moduleColour("controls","accent",Theme.accent),
        green: Theme.green,
        yellow: Theme.yellow,
        red: Theme.red,
        blue: Theme.blue
    })

    readonly property string title:
        `${AccountService.user}<font color="${Theme.moduleColour("controls","muted",Theme.textMuted)}">@</font>${MachineService.host}`

    readonly property string uptime: StatsService.duration(StatsService.uptime)

    // CPU model as fastfetch prints it, without trademark symbols.
    readonly property string cpu:
        StatsService.cpuModel.replace(/\((R|TM)\)/g, "").replace(/\s+/g, " ").trim()

    Component.onCompleted: MachineService.refresh()

    // One greeting line: glyph and key in the accent, then the value. Keys are
    // padded to the longest so values line up. `note` is a second value that
    // must stay visible (the live percentage after a long CPU model), so the
    // value is capped at its own width and elides first.
    component Line: RowLayout {
        id: line

        property string icon: ""
        property string key: ""
        property string value: ""
        property string note: ""

        visible: line.value !== ""
        spacing: 0

        Text { objectName:"design:ImpastoBlock:1";
            text: `${line.icon} ${line.key.padEnd(6)}  `
            font.family: Theme.fontMono
            font.pixelSize: root.type
            color: Theme.moduleColour("controls","accent",Theme.accent)
        }

        Text { objectName:"design:ImpastoBlock:2";
            Layout.fillWidth: true
            // Rounded up, or a fractional layout width elides the last
            // character.
            Layout.maximumWidth: Math.ceil(implicitWidth)
            text: line.value
            elide: Text.ElideRight
            font.family: Theme.fontMono
            font.pixelSize: root.type
            color: Theme.moduleColour("controls","foreground",Theme.text)
        }

        Text { objectName:"design:ImpastoBlock:3";
            visible: line.note !== ""
            text: `  ${line.note}`
            font.family: Theme.fontMono
            font.pixelSize: root.type
            color: Theme.moduleColour("controls","muted",Theme.textMuted)
        }
    }

    // `user@host` with the `@` muted.
    component Title: Text {
        textFormat: Text.StyledText
        text: `<font color="${Theme.moduleColour("controls","accent",Theme.accent)}">󰣇</font> ${root.title}`
        elide: Text.ElideRight
        font.family: Theme.fontMono
        font.pixelSize: root.type
        font.weight: Font.DemiBold
        color: Theme.moduleColour("controls","foreground",Theme.text)
    }

    // The five colour daubs from the greeting's last line.
    component Daubs: Row {
        id: daubs

        property int dot: 7

        spacing: 5

        Repeater {
            model: ["accent", "green", "yellow", "red", "blue"]

            Rectangle { objectName:"design:ImpastoBlock:4";
                required property string modelData

                width: daubs.dot
                height: daubs.dot
                radius: daubs.dot / 2
                antialiasing: true
                color: root.paints[modelData]

                Behavior on color { ColorAnimation { duration: Theme.paletteTransition } }
            }
        }
    }

    component Hairline: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        implicitHeight: 1
        color: Theme.hairline
    }

    // ── SQUARE ──────────────────────────────────────────────────────────────

    Column { objectName:"design:ImpastoBlock:5";
        anchors.centerIn: parent
        width: parent.width
        visible: !root.wide && !root.tall
        spacing: 4

        PaletteBoard {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 46
        }

        Title {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        Text { objectName:"design:ImpastoBlock:6";
            width: parent.width
            textFormat: Text.StyledText
            text: `<font color="${Theme.moduleColour("controls","accent",Theme.accent)}">󰅐</font> ${root.uptime}`
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            font.family: Theme.fontMono
            font.pixelSize: root.type
            color: Theme.moduleColour("controls","foreground",Theme.text)
        }

        Daubs {
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // ── ROW ─────────────────────────────────────────────────────────────────
    //
    // Logo left, machine column right, as fastfetch prints it.

    RowLayout { objectName:"design:ImpastoBlock:7";
        anchors.fill: parent
        visible: root.wide
        spacing: 14

        PaletteBoard {
            Layout.alignment: Qt.AlignVCenter
            size: 64
        }

        ColumnLayout { objectName:"design:ImpastoBlock:8";
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Title { Layout.fillWidth: true }
            Line { Layout.fillWidth: true; icon: "󰣇"; key: "os"; value: MachineService.os }
            Line { Layout.fillWidth: true; icon: "󰒓"; key: "kernel"; value: MachineService.kernel }
            Line { Layout.fillWidth: true; icon: "󰅐"; key: "uptime"; value: root.uptime }
            Line {
                Layout.fillWidth: true
                icon: "󰏗"
                key: "pkgs"
                value: MachineService.packages === null ? "" : String(MachineService.packages)
            }

            RowLayout { objectName:"design:ImpastoBlock:9";
                spacing: 0

                Text { objectName:"design:ImpastoBlock:10";
                    text: `󰏘 ${"colors".padEnd(6)}  `
                    font.family: Theme.fontMono
                    font.pixelSize: root.type
                    color: Theme.moduleColour("controls","accent",Theme.accent)
                }

                Daubs { Layout.alignment: Qt.AlignVCenter }
            }
        }
    }

    // ── LARGE SQUARE ────────────────────────────────────────────────────────
    //
    // The full greeting: logo and name beside the machine, the load under a
    // hairline, then uptime and daubs, in the config's order.

    ColumnLayout { objectName:"design:ImpastoBlock:11";
        anchors.centerIn: parent
        width: parent.width
        visible: root.tall
        spacing: 2

        RowLayout { objectName:"design:ImpastoBlock:12";
            Layout.fillWidth: true
            Layout.bottomMargin: 2
            spacing: 14

            Column { objectName:"design:ImpastoBlock:13";
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                PaletteBoard {
                    anchors.horizontalCenter: parent.horizontalCenter
                    size: 72
                }

                Text { objectName:"design:ImpastoBlock:14";
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "impasto"
                    font.family: Theme.fontSignature
                    font.pixelSize: 20
                    color: Theme.moduleColour("controls","foreground",Theme.text)
                }
            }

            ColumnLayout { objectName:"design:ImpastoBlock:15";
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Title { Layout.fillWidth: true }
                Hairline { Layout.topMargin: 2; Layout.bottomMargin: 2 }
                Line { Layout.fillWidth: true; icon: "󰣇"; key: "os"; value: MachineService.os }
                Line { Layout.fillWidth: true; icon: "󰒓"; key: "kernel"; value: MachineService.kernel }
                Line { Layout.fillWidth: true; icon: "󰖳"; key: "wm"; value: MachineService.wm }
                Line { Layout.fillWidth: true; icon: "󰆍"; key: "shell"; value: MachineService.shell }
            }
        }

        Hairline {}

        Line {
            Layout.fillWidth: true
            icon: "󰘚"
            key: "cpu"
            value: root.cpu
            note: StatsService.ready ? `${Math.round(StatsService.cpu)}%` : ""
        }

        Line {
            Layout.fillWidth: true
            icon: "󰋊"
            key: "disk"
            value: root.disk
                ? `${StatsService.bytes(root.disk.used, 0)} / ${StatsService.bytes(root.disk.total, 0)}`
                : ""
            note: root.disk && root.disk.total > 0
                ? `${Math.round(root.disk.used / root.disk.total * 100)}%`
                : ""
        }

        Line {
            Layout.fillWidth: true
            icon: "󰍛"
            key: "mem"
            value: StatsService.memoryTotal > 0
                ? `${StatsService.bytes(StatsService.memoryUsed)} / ${StatsService.bytes(StatsService.memoryTotal)}`
                : ""
            note: StatsService.memoryTotal > 0
                ? `${Math.round(StatsService.memoryFraction * 100)}%`
                : ""
        }

        Line {
            Layout.fillWidth: true
            icon: "󰏗"
            key: "pkgs"
            value: MachineService.packages === null ? "" : String(MachineService.packages)
        }

        Hairline {}

        Line { Layout.fillWidth: true; icon: "󰅐"; key: "uptime"; value: root.uptime }

        RowLayout { objectName:"design:ImpastoBlock:16";
            spacing: 0

            Text { objectName:"design:ImpastoBlock:17";
                text: `󰏘 ${"colors".padEnd(6)}  `
                font.family: Theme.fontMono
                font.pixelSize: root.type
                color: Theme.moduleColour("controls","accent",Theme.accent)
            }

            Daubs {
                Layout.alignment: Qt.AlignVCenter
                dot: 8
            }
        }
    }
}
