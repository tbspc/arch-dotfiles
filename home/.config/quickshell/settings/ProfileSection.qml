import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import "../components"
import "../services"
import "../theme"

SettingsSection {
    id: root
    property string tab: "account"
    readonly property real regionOffset: region.y
    property string zone: Qt.formatDateTime(new Date(), "t")
    Process {
        running: true
        command: ["timedatectl", "show", "--property=Timezone", "--value"]
        stdout: StdioCollector { onStreamFinished: if (text.trim()) root.zone = text.trim() }
    }
    FileDialog {
        id: picker
        title: Tr.t("Choose a profile photo")
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp)"]
        onAccepted: AccountService.setPicture(decodeURIComponent(String(selectedFile).replace(/^file:\/\//, "")))
    }
    SettingGroup {
        title: Tr.t("Account")
        Item {
            Layout.fillWidth: true
            implicitHeight: 108
            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 18
                Avatar { Layout.preferredWidth: 64; Layout.preferredHeight: 64; source: AccountService.avatar; initials: AccountService.initials; ring: "transparent" }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text { text: Tr.t("Profile photo"); color: Theme.textIn(QsWindow.window); font.family: Theme.fontIn(QsWindow.window); font.pixelSize: 14; font.weight: Font.Medium }
                    Text { Layout.fillWidth: true; text: AccountService.busy === "picture" ? Tr.t("Saving your photo…") : Tr.t("Shown on your lock screen and login screen."); wrapMode: Text.WordWrap; color: Theme.mutedIn(QsWindow.window); font.family: Theme.fontIn(QsWindow.window); font.pixelSize: 12 }
                }
                PillButton { text: Tr.t("Upload photo"); onClicked: picker.open() }
                IconButton { visible: AccountService.avatar !== ""; icon: "󰆴"; onClicked: AccountService.clearPicture() }
            }
        }
        SettingField {
            label: Tr.t("Display name")
            reading: Tr.t("How your name appears on the lock and login screens.")
            placeholder: AccountService.systemName || AccountService.user
            value: AccountService.name
            onEdited: value => AccountService.setName(value)
        }
        SettingRow {
            label: Tr.t("Username")
            reading: Tr.t("Your Linux login name.")
            Text { text: AccountService.user || "—"; color: Theme.mutedIn(QsWindow.window); font.family: Theme.fontIn(QsWindow.window); font.pixelSize: 14 }
        }
        SettingRow {
            visible: AccountService.failure !== ""
            label: Tr.t("Could not save the account change")
            reading: AccountService.failure
            alarm: true
        }
    }
    SettingGroup {
        id: region
        title: Tr.t("Region")
        SettingRow {
            label: Tr.t("Language")
            reading: Tr.t("Language used throughout settings.")
            SegmentedControl { options: Tr.languages; current: SettingsService.language; onSelected: id => SettingsService.set("language", id) }
        }
        SettingRow {
            label: Tr.t("Time zone")
            reading: Tr.t("Automatically follows your device.")
            Text { text: root.zone; color: Theme.mutedIn(QsWindow.window); font.family: Theme.fontIn(QsWindow.window); font.pixelSize: 14 }
        }
    }
    function focusRegion(): void { region.forceActiveFocus() }
}
