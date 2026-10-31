// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E T T I N G   F I E L D                                              │
// │   a preference that is a piece of text                                   │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../theme"
import "../services"

// A setting row whose control is a text field, as wide as a slider's track
// and figure so the two line up. The placeholder is what applies while the
// field is empty.
Item { objectName:"design:SettingField:1";
    id: root

    property string label: ""
    property string reading: ""
    property bool alarm: false

    property string placeholder: ""
    property string value: ""

    signal edited(string value)

    Layout.fillWidth: true
    implicitHeight: Math.max(SettingsDesignService.style.rowHeight,body.implicitHeight+2*SettingsDesignService.style.rowPadding)

    SettingDivider {}

    RowLayout { objectName:"design:SettingField:2";
        id: body

        anchors.fill: parent
        anchors.leftMargin:SettingsDesignService.forma?SettingsDesignService.style.cardPadding:14
        anchors.rightMargin:SettingsDesignService.forma?SettingsDesignService.style.cardPadding:14
        spacing: 16

        SettingLabel {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            label: root.label
            reading: root.reading
            alarm: root.alarm
        }

        Rectangle { objectName:"design:SettingField:3";
            Layout.preferredWidth: SettingsDesignService.style.navigation === "studio" ? Math.min(300, root.width * .40) : 300
            Layout.preferredHeight: Theme.controlSizeIn(QsWindow.window, 30)
            Layout.alignment: Qt.AlignVCenter
            radius:Theme.radiusIn(QsWindow.window,"fieldRadius",Theme.radiusSmall)
            color: SettingsDesignService.style.navigation === "studio" ? SettingsDesignService.style.fieldBackground : Theme.island
            border.color: input.activeFocus ? Theme.accentIn(QsWindow.window) : Theme.borderIn(QsWindow.window)
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

            TextInput { objectName:"design:SettingField:4";
                id: input

                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                text: root.value
                font.family: Theme.fontIn(QsWindow.window)
                font.pixelSize: Theme.textSizeIn(QsWindow.window, Theme.fontSizeSmall)
                color: Theme.textIn(QsWindow.window)
                selectByMouse: true
                selectionColor: Theme.accentIn(QsWindow.window)
                selectedTextColor: Theme.accentTextIn(QsWindow.window)
                clip: true

                onTextEdited: root.edited(input.text)
                Keys.onEscapePressed: { input.text = ""; root.edited("") }

                Text { objectName:"design:SettingField:5";
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    visible: input.text === ""
                    text: root.placeholder
                    elide: Text.ElideRight
                    font: input.font
                    color: Theme.mutedIn(QsWindow.window)
                }
            }
        }
    }
}
