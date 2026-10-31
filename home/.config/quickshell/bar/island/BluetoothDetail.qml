// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   B L U E T O O T H   D E T A I L                                        │
// │   paired and nearby bluetooth devices                                    │
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

// The list behind the Bluetooth tile. `connected` is writable on a device, so
// connecting is a property assignment and the state comes back over D-Bus.
//
// Discovery runs only while this view exists: a lingering scan costs power and
// floods the list.
ColumnLayout { objectName:"design:BluetoothDetail:1";
    id: root

    signal back()

    // No back arrow when opened from the bar, where there is nothing to go
    // back to.
    property bool backable: true

    // Unnamed devices are folded away rather than dropped.
    property bool showUnnamed: false

    readonly property var listed: root.showUnnamed
        ? BluetoothService.devices.concat(BluetoothService.unnamedDevices)
        : BluetoothService.devices

    spacing: Theme.cardGap

    Component.onCompleted: {
        if (BluetoothService.enabled)
            BluetoothService.setDiscovering(true)
    }
    Component.onDestruction: BluetoothService.setDiscovering(false)

    // The heading a module's card has (`ModuleCard`), with the back arrow in
    // front of it when there is somewhere to go back to.
    RowLayout { objectName:"design:BluetoothDetail:2";
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.cardMark
        spacing: 12

        IconButton {
            icon: "󰅁"
            iconSize: 14
            visible: root.backable
            onClicked: root.back()
        }

        RingIndicator {
            Layout.preferredWidth: Theme.cardMark
            Layout.preferredHeight: Theme.cardMark
            thickness: 3
            progress: 0
            trackColor: Theme.indicatorDim

            Text { objectName:"design:BluetoothDetail:3";
                anchors.centerIn: parent
                text: BluetoothService.icon
                font.family: Theme.fontMono
                font.pixelSize: 18
                color: BluetoothService.enabled ? Theme.moduleColour("bluetooth","accent",Theme.indicator) : Theme.moduleColour("bluetooth","muted",Theme.textMuted)
            }
        }

        ColumnLayout { objectName:"design:BluetoothDetail:4";
            Layout.fillWidth: true
            spacing: 2

            Text { objectName:"design:BluetoothDetail:5";
                Layout.fillWidth: true
                text: "Bluetooth"
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                color: Theme.moduleColour("bluetooth","foreground",Theme.text)
            }

            Text { objectName:"design:BluetoothDetail:6";
                Layout.fillWidth: true
                text: BluetoothService.enabled
                    ? (BluetoothService.discovering ? "Looking for devices…" : BluetoothService.summary)
                    : "Adapter off"
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.moduleColour("bluetooth","muted",Theme.textMuted)
            }
        }

        ToggleSwitch {
            checked: BluetoothService.enabled
            onToggled: checked => {
                BluetoothService.toggle()
                BluetoothService.setDiscovering(checked)
            }
        }
    }

    Text { objectName:"design:BluetoothDetail:7";
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.listed.length === 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: BluetoothService.enabled ? "Nothing found yet" : "Turn Bluetooth on to see devices"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.moduleColour("bluetooth","muted",Theme.textMuted)
    }

    ListView { objectName:"design:BluetoothDetail:8";
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.listed.length > 0
        clip: true
        spacing: 4
        model: ScriptModel {
            values: root.listed
            comparisonMode: ObjectComparison.Identity
        }
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            id: entry

            required property var modelData

            width: ListView.view.width
            height: 48
            radius: Theme.radiusMedium
            color: entry.modelData.connected || entryMouse.containsMouse
                ? Theme.surfaceHoverIn(QsWindow.window) : Theme.surfaceIn(QsWindow.window)
            border.color: entry.modelData.connected ? Theme.moduleColour("bluetooth","accent",Theme.accent) : Theme.borderIn(QsWindow.window)
            border.width: 1

            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

            RowLayout { objectName:"design:BluetoothDetail:9";
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: 10

                Text { objectName:"design:BluetoothDetail:10";
                    text: BluetoothService.deviceIcon(entry.modelData)
                    font.family: Theme.fontMono
                    font.pixelSize: 15
                    color: entry.modelData.connected ? Theme.moduleColour("bluetooth","accent",Theme.accent) : Theme.moduleColour("bluetooth","muted",Theme.textMuted)
                }

                ColumnLayout { objectName:"design:BluetoothDetail:11";
                    Layout.fillWidth: true
                    spacing: 0

                    Text { objectName:"design:BluetoothDetail:12";
                        Layout.fillWidth: true
                        // The address rather than BlueZ's Alias, which for a
                        // device with no name is the address with dashes.
                        text: BluetoothService.isNamed(entry.modelData)
                            ? entry.modelData.name : entry.modelData.address
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: entry.modelData.connected ? Font.DemiBold : Font.Normal
                        color: entry.modelData.connected ? Theme.moduleColour("bluetooth","accent",Theme.accent) : Theme.moduleColour("bluetooth","foreground",Theme.text)
                    }

                    Text { objectName:"design:BluetoothDetail:13";
                        Layout.fillWidth: true
                        text: {
                            if (entry.modelData.pairing) return "Pairing…"
                            const bits = []
                            bits.push(entry.modelData.connected ? "Connected"
                                : (entry.modelData.paired ? "Paired" : "Available"))
                            if (entry.modelData.batteryAvailable)
                                bits.push(`${Math.round(entry.modelData.battery * 100)}%`)
                            return bits.join(" · ")
                        }
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        color: Theme.moduleColour("bluetooth","muted",Theme.textMuted)
                    }
                }

                Text { objectName:"design:BluetoothDetail:14";
                    visible: entry.modelData.connected
                    text: "󰄬"
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                    color: Theme.moduleColour("bluetooth","accent",Theme.accent)
                }
            }

            MouseArea {
                id: entryMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: BluetoothService.connectDevice(entry.modelData)
            }
        }
    }

    // The fold for devices without a name.
    Item { objectName:"design:BluetoothDetail:15";
        Layout.alignment: Qt.AlignHCenter
        visible: BluetoothService.unnamedCount > 0
        implicitWidth: unnamedRow.implicitWidth + 16
        implicitHeight: unnamedRow.implicitHeight + 8

        Row { objectName:"design:BluetoothDetail:16";
            id: unnamedRow
            anchors.centerIn: parent
            spacing: 6

            Text { objectName:"design:BluetoothDetail:17";
                text: root.showUnnamed ? "󰅃" : "󰅀"
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeLabel
                color: unnamedMouse.containsMouse ? Theme.moduleColour("bluetooth","foreground",Theme.text) : Theme.moduleColour("bluetooth","muted",Theme.textMuted)
            }

            Text { objectName:"design:BluetoothDetail:18";
                text: BluetoothService.unnamedCount === 1
                    ? "1 unnamed device nearby"
                    : `${BluetoothService.unnamedCount} unnamed devices nearby`
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
                color: unnamedMouse.containsMouse ? Theme.moduleColour("bluetooth","foreground",Theme.text) : Theme.moduleColour("bluetooth","muted",Theme.textMuted)
            }
        }

        MouseArea {
            id: unnamedMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showUnnamed = !root.showUnnamed
        }
    }
}
