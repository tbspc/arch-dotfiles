// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E S S I O N   S E C T I O N                                          │
// │   session · account, lock screen and idle                                │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Dialogs
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import "../theme"
import "../services"
import "../components"
import "../lock"

// The lock screen, face unlock and the idle policy, a part each. The shell locks through
// ext-session-lock and shows the blurred desktop behind the lock. The blur
// slider previews over the wallpaper, since the lock's own capture of the
// screen only exists once locked.
SettingsSection {
    id: root

    // The visible part; set by `SettingsPanel`.
    property string tab: ""

    FileDialog {
        id: picker

        title: Tr.t("Choose a picture")
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp)"]
        onAccepted: {
            const url = String(picker.selectedFile)
            AccountService.setPicture(url.startsWith("file://") ? url.slice(7) : url)
        }
    }


    Loader {
        Layout.fillWidth: true
        active: root.tab === "animations"
        visible: active
        sourceComponent: LockAnimationsSection {}
    }

    // ── LOCK SCREEN ─────────────────────────────────────────────────────────

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.tab === "lock"
        spacing: root.spacing

        Loader {
            Layout.fillWidth: true
            active: root.tab === "lock"
            visible: active
            sourceComponent: LockCustomizationPage {}
        }

        SettingGroup {
            title: Tr.t("You")
            note: Tr.t("Your account's name and picture, on the lock and login screens.")
            hint: Tr.t("The name is your account's full name, and the picture is kept where the login screen reads it too, made square. Click the picture or drop an image on the card to change it.")

            // Click the picture to choose a file, or drop an image on the row.
            Item {
                Layout.fillWidth: true
                implicitHeight: 72

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Theme.radiusMedium
                    color: Theme.colourIn(QsWindow.window,"hoverColor",Theme.islandSurfaceHover)
                    border.color: Theme.accentIn(QsWindow.window)
                    border.width: 1
                    visible: drop.containsDrag
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 16

                    Item {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        Layout.alignment: Qt.AlignVCenter

                        Avatar {
                            anchors.fill: parent
                            source: AccountService.avatar
                            initials: AccountService.initials
                        }

                        // Camera overlay on hover.
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Theme.scrim
                            opacity: faceMouse.containsMouse ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.durationFast }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰄄"
                                font.family: Theme.fontMono
                                font.pixelSize: 16
                                color: Theme.scrimText
                            }
                        }

                        MouseArea {
                            id: faceMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: picker.open()
                        }
                    }

                    // The chosen path, the account's avatar, or a prompt.
                    SettingLabel {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        label: Tr.t("Picture")
                        reading: {
                            if (AccountService.busy === "picture")
                                return Tr.t("Saving…")
                            if (AccountService.failedKind === "picture")
                                return Tr.t("The picture was not changed")
                            if (AccountService.avatar === "")
                                return Tr.t("Click it, or drop an image here")
                            if (SettingsService.userAvatar !== "" || !AccountService.shared)
                                return Tr.t("The lock screen only, until ./setup system")
                            return Tr.t("On the lock and login screens")
                        }
                        alarm: AccountService.failedKind === "picture"
                    }

                    PillButton {
                        Layout.alignment: Qt.AlignVCenter
                        text: Tr.t("Clear")
                        icon: "󰜉"
                        implicitWidth: 92
                        implicitHeight: 30
                        visible: SettingsService.userAvatar !== ""
                            || (AccountService.shared && AccountService.systemAvatar !== "")
                        enabled: AccountService.busy === ""
                        onClicked: AccountService.clearPicture()
                    }
                }

                DropArea {
                    id: drop

                    anchors.fill: parent
                    // Stored as a path, not a file:// URL.
                    onDropped: event => {
                        if (event.urls.length === 0)
                            return
                        const url = String(event.urls[0])
                        AccountService.setPicture(url.startsWith("file://") ? url.slice(7) : url)
                    }
                }
            }

            // The account's full name where AccountsService can change it;
            // otherwise a name for the lock screen alone, as before.
            SettingField {
                label: Tr.t("Name")
                placeholder: AccountService.user
                // While it is written, what was typed, so the field never
                // jumps back to the old name under the hand.
                value: AccountService.busy === "name" || AccountService.namePause.running
                    ? AccountService.pendingName
                    : SettingsService.userName !== "" || !AccountService.accounts
                    ? SettingsService.userName : AccountService.fullName
                onEdited: text => AccountService.setName(text)
            }
        }

        // What is playing, on the lock. Each tile is the lock drawn small:
        // the clock, and under it nothing, the cover, or the cover and lines.
        SettingGroup {
            title: Tr.t("Music")
            note: Tr.t("Only while something is playing.")
            hint: Tr.t("The lyrics follow the Lyrics switch on the Modules page, and are looked up on lrclib.net.")

            SettingTiles {
                label: Tr.t("Show")

                Repeater {
                    model: [
                        { id: "off", label: "Nothing" },
                        { id: "player", label: "The player" },
                        { id: "lyrics", label: "With lyrics" }
                    ]

                    PreviewTile {
                        id: musicTile

                        required property var modelData

                        stageHeight: 120
                        caption: Tr.t(musicTile.modelData.label)
                        selected: SettingsService.lockMusic === musicTile.modelData.id
                        onPicked: SettingsService.set("lockMusic", musicTile.modelData.id)

                        Image {
                            id: musicGround

                            anchors.fill: parent
                            source: WallpaperService.currentWallpaper
                                ? `file://${WallpaperService.currentWallpaper}` : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            asynchronous: true
                            sourceSize.width: 320
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: musicGround
                            visible: musicGround.status === Image.Ready
                            blurEnabled: true
                            blur: 1
                            blurMax: 16
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: musicTile.modelData.id === "off" ? 38 : 10
                            text: "9:41"
                            font.family: Theme.fontDisplay
                            font.pixelSize: musicTile.modelData.id === "off" ? 30 : 16
                            font.weight: Font.Bold
                            color: Theme.textIn(QsWindow.window)
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 44
                            visible: musicTile.modelData.id !== "off"
                            spacing: 10

                            Rectangle {
                                width: 44
                                height: 44
                                radius: 8
                                color: Theme.accentIn(QsWindow.window)
                            }

                            Column {
                                visible: musicTile.modelData.id === "lyrics"
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Repeater {
                                    model: [0.35, 1, 0.35]

                                    Rectangle {
                                        required property real modelData
                                        required property int index

                                        width: index === 1 ? 52 : 40
                                        height: 4
                                        radius: 2
                                        color: Theme.textIn(QsWindow.window)
                                        opacity: modelData
                                    }
                                }
                            }
                        }
                    }
                }
            }

            SettingTiles {
                label: Tr.t("Behind it")
                visible: SettingsService.lockMusic !== "off"

                Repeater {
                    model: [
                        { id: "cover", label: "The cover" },
                        { id: "desktop", label: "The desktop" }
                    ]

                    PreviewTile {
                        id: groundTile

                        required property var modelData

                        readonly property bool onCover: groundTile.modelData.id === "cover"

                        stageHeight: 120
                        caption: Tr.t(groundTile.modelData.label)
                        selected: SettingsService.lockMusicGround === groundTile.modelData.id
                        onPicked: SettingsService.set("lockMusicGround", groundTile.modelData.id)

                        // The cover playing now, or the wallpaper standing in.
                        Image {
                            id: behind

                            anchors.fill: parent
                            source: groundTile.onCover && MediaService.artUrl !== ""
                                ? MediaService.artUrl
                                : (WallpaperService.currentWallpaper
                                    ? `file://${WallpaperService.currentWallpaper}` : "")
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            asynchronous: true
                            sourceSize.width: groundTile.onCover ? 48 : 320
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: behind
                            visible: behind.status === Image.Ready
                            blurEnabled: true
                            blur: 1
                            blurMax: groundTile.onCover ? 32 : 16
                            brightness: groundTile.onCover ? -0.28 : -0.05
                            saturation: groundTile.onCover ? 0.25 : 0
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 44
                            height: 44
                            radius: 8
                            color: Theme.accentIn(QsWindow.window)
                        }
                    }
                }
            }
        }

    }

    // ── WHEN YOU LEAVE ──────────────────────────────────────────────────────

    SettingGroup {
        visible: root.tab === "idle"
        title: Tr.t("When you leave it alone")
        note: Tr.t("All three are off by default.")
        hint: Tr.t("The shell uses the compositor's idle notifications, and media that inhibits idle (mpv, browsers) holds all three off. Set screen off after the lock, since the lock captures the screen as it starts; suspend always locks first and is skipped if the lock does not come up.")

        SettingSlider {
            label: Tr.t("Lock after")
            value: SettingsService.idleLock
            from: 0
            to: 60
            unit: " min"
            reading: SettingsService.idleLock === 0
                ? Tr.t("Never") : `${SettingsService.idleLock} min`
            onMoved: value => SettingsService.set("idleLock", Math.round(value))
        }

        // Warns when the screen would turn off before the lock: the lock
        // captures the desktop as it goes up and cannot capture a screen that
        // is already off.
        SettingSlider {
            label: Tr.t("Screen off after")
            value: SettingsService.idleScreen
            from: 0
            to: 60
            unit: " min"
            reading: {
                if (SettingsService.idleScreen === 0)
                    return Tr.t("Never")
                if (SettingsService.idleLock === 0
                        || SettingsService.idleScreen >= SettingsService.idleLock)
                    return `${SettingsService.idleScreen} min`
                return `${SettingsService.idleScreen} min · ${Tr.t("before the lock")}`
            }
            onMoved: value => SettingsService.set("idleScreen", Math.round(value))
        }

        SettingSlider {
            label: Tr.t("Suspend after")
            value: SettingsService.idleSuspend
            from: 0
            to: 60
            unit: " min"
            reading: SettingsService.idleSuspend === 0
                ? Tr.t("Never") : `${SettingsService.idleSuspend} min`
            onMoved: value => SettingsService.set("idleSuspend", Math.round(value))
        }
    }
}
