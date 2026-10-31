// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   A U T H   P A N E L                                                    │
// │   a program asks for root · what it wants, and the password              │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import Quickshell.Io

import "../../theme"
import "../../services"
import "../../components"

// What is being asked for comes first, then the lock's pill for the
// password, then who asks and the two answers. Closing the panel any way at
// all answers no: a request left open would wait on a field nobody can see.
Item { objectName:"design:AuthPanel:1";
    id: root

    readonly property var flow: PolkitService.flow
    readonly property bool waiting: root.flow !== null && !root.flow.isResponseRequired

    readonly property int pillHeight: 56
    readonly property int face: 40

    // Caps Lock, from the compositor: Qt does not report it. Read on open
    // and on each press of the key, while the panel is up.
    property bool capsLock: false

    Process {
        id: capsReader

        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.capsLock = (JSON.parse(text).keyboards ?? []).some(board => board.capsLock)
                } catch (error) {
                    root.capsLock = false
                }
            }
        }
    }

    Component.onCompleted: field.forceActiveFocus()
    Component.onDestruction: PolkitService.cancel()

    function answer(): void {
        if (field.text === "" || root.waiting)
            return
        PolkitService.submit(field.text)
        field.clear()
    }

    // ── WHAT IS ASKED ───────────────────────────────────────────────────────

    Row { objectName:"design:AuthPanel:2";
        id: header

        x: 6
        y: 4
        width: parent.width - 12
        spacing: 14

        Rectangle { objectName:"design:AuthPanel:3";
            width: 40
            height: 40
            radius: width / 2
            color: Theme.islandSurface

            Text { objectName:"design:AuthPanel:4";
                anchors.centerIn: parent
                text: "󰦝"
                font.family: Theme.fontMono
                font.pixelSize: 20
                color: Theme.moduleColour("auth","accent",Theme.accent)
            }
        }

        Column { objectName:"design:AuthPanel:5";
            width: header.width - 54
            spacing: 3

            Text { objectName:"design:AuthPanel:6";
                text: Tr.t("Authentication required")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: Theme.moduleColour("auth","foreground",Theme.text)
            }

            Text { objectName:"design:AuthPanel:7";
                width: parent.width
                text: root.flow?.message ?? ""
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeRegular
                color: Theme.moduleColour("auth","muted",Theme.textMuted)
            }
        }
    }

    // ── THE PASSWORD ────────────────────────────────────────────────────────

    Rectangle { objectName:"design:AuthPanel:8";
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 8
        width: parent.width - 12
        height: root.pillHeight
        radius: height / 2
        color: Theme.islandSurface
        border.width: 1.5
        border.color: PolkitService.failed ? Theme.indicatorBad
            : field.activeFocus ? Theme.moduleColour("auth","accent",Theme.accent) : Theme.islandBorder

        Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

        // Shakes on a refused password, as the lock does.
        SequentialAnimation {
            id: refusal

            loops: 2
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"
                to: -9; duration: 55; easing.type: Easing.OutCubic }
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"
                to: 9; duration: 55; easing.type: Easing.OutCubic }
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"
                to: 0; duration: 55; easing.type: Easing.OutCubic }
        }

        Connections {
            target: PolkitService
            function onFailedChanged(): void {
                if (PolkitService.failed)
                    refusal.restart()
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: field.forceActiveFocus()
        }

        Avatar {
            id: picture

            x: 8
            anchors.verticalCenter: parent.verticalCenter
            width: root.face
            height: root.face
            source: AccountService.avatar
            initials: AccountService.initials
        }

        TextInput { objectName:"design:AuthPanel:9";
            id: field

            anchors.left: picture.right
            anchors.leftMargin: 14
            anchors.right: send.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter

            echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
            passwordCharacter: "●"
            passwordMaskDelay: 0
            enabled: !root.waiting
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.letterSpacing: echoMode === TextInput.Password ? 3 : 0
            color: Theme.moduleColour("auth","foreground",Theme.text)
            selectionColor: Theme.moduleColour("auth","accent",Theme.accent)
            selectedTextColor: Theme.accentText
            clip: true

            onAccepted: root.answer()
            Keys.onReleased: event => {
                if (event.key === Qt.Key_CapsLock)
                    capsReader.running = true
            }
            onTextChanged: if (text !== "") PolkitService.failed = false

            // What polkit asks for ("Password:"), or why it was refused.
            Text { objectName:"design:AuthPanel:10";
                anchors.verticalCenter: parent.verticalCenter
                visible: field.text === ""
                text: PolkitService.failed ? Tr.t("That password didn't work")
                    : root.flow?.supplementaryIsError && root.flow?.supplementaryMessage
                        ? root.flow.supplementaryMessage
                    : (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || Tr.t("Password")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeRegular
                color: PolkitService.failed || root.flow?.supplementaryIsError
                    ? Theme.indicatorBad : Theme.moduleColour("auth","muted",Theme.textMuted)
            }
        }

        Rectangle { objectName:"design:AuthPanel:11";
            id: send

            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: root.face
            height: root.face
            radius: width / 2
            color: field.text !== "" && !root.waiting ? Theme.moduleColour("auth","accent",Theme.accent) : Theme.islandSurfaceHover

            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

            Text { objectName:"design:AuthPanel:12";
                anchors.centerIn: parent
                text: "󰁔"
                font.family: Theme.fontMono
                font.pixelSize: 18
                color: field.text !== "" && !root.waiting ? Theme.accentText : Theme.moduleColour("auth","muted",Theme.textMuted)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.answer()
            }
        }
    }

    // ── WHO ASKS, AND THE ANSWERS ───────────────────────────────────────────

    Text { objectName:"design:AuthPanel:13";
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.right: buttons.left
        anchors.rightMargin: 12
        anchors.verticalCenter: buttons.verticalCenter
        // Caps Lock takes the line while it is on: it is the likeliest reason
        // for a refused password.
        text: root.capsLock ? `󰪛  ${Tr.t("Caps Lock is on")}` : (root.flow?.actionId ?? "")
        elide: Text.ElideMiddle
        font.family: root.capsLock ? Theme.fontFamily : Theme.fontMono
        font.pixelSize: Theme.fontSizeSmall
        font.weight: root.capsLock ? Font.DemiBold : Font.Normal
        color: root.capsLock ? Theme.indicatorWarn : Theme.moduleColour("auth","muted",Theme.textMuted)
    }

    Row { objectName:"design:AuthPanel:14";
        id: buttons

        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.bottom: parent.bottom
        spacing: 8

        PillButton {
            text: Tr.t("Cancel")
            implicitHeight: 34
            onClicked: PolkitService.cancel()
        }

        PillButton {
            text: Tr.t("Authorize")
            implicitHeight: 34
            active: true
            enabled: field.text !== "" && !root.waiting
            onClicked: root.answer()
        }
    }
}
