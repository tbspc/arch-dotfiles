// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   N E T W O R K   M O D U L E                                            │
// │   network · link status, radio switch when open                          │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts

import "../../theme"
import "../../services"
import "../../components"

// The chip is the link's glyph and the network name. The detail shows the link
// type, internet reachability and the Wi-Fi switch; choosing a network is done
// in the control centre panel.
Item { objectName:"design:NetworkModule:1";
    id: root

    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight

    Component.onCompleted: NetworkService.refresh()

    // Shared with the desktop widget.
    readonly property string stateLine: NetworkService.stateLine

    Loader {
        id: holder
        anchors.fill: parent
        sourceComponent: detail
    }

    Component {
        id: detail

        ModuleCard {
            title: NetworkService.connectionName
            subtitle: root.stateLine

            mark: RingIndicator {
                anchors.fill: parent
                thickness: 3
                progress: 0
                trackColor: Theme.indicatorDim

                Text { objectName:"design:NetworkModule:2";
                    anchors.centerIn: parent
                    text: NetworkService.icon
                    font.family: Theme.fontMono
                    font.pixelSize: 18
                    color: NetworkService.online ? Theme.moduleColour("network","accent",Theme.indicator) : Theme.moduleColour("network","muted",Theme.textMuted)
                }
            }

            RowLayout { objectName:"design:NetworkModule:3";
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.cardRow
                spacing: 10

                Text { objectName:"design:NetworkModule:4";
                    Layout.fillWidth: true
                    text: "Wi-Fi"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.moduleColour("network","muted",Theme.textMuted)
                }

                Text { objectName:"design:NetworkModule:5";
                    text: NetworkService.wifiConnected ? "connected" : (NetworkService.wifiEnabled ? "on" : "off")
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.moduleColour("network","foreground",Theme.text)
                }

                ToggleSwitch {
                    checked: NetworkService.wifiEnabled
                    onToggled: NetworkService.toggleWifi()
                }
            }

            CardFact {
                name: "Link"
                value: {
                    const link = NetworkService.wiredConnected ? "Wired"
                        : NetworkService.wifiConnected ? "Wireless" : "None"
                    return NetworkService.online ? `${link} · internet reached` : link
                }
            }
        }
    }
}
