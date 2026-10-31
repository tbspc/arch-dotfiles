import "../" as Config
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../services"
import "../components"

SettingsSection {
    id: root
    property var initial: null
    readonly property LockFullscreenEditor editor: LockFullscreenEditor {
        onFinished: (mode, selected) => {
            preview.mode = mode
            preview.selected = selected
        }
    }
    Component.onCompleted: root.initial = SettingsService.snapshot()

    SettingGroup {
        title:Tr.t("Lock screen presets")
        SettingRow {label:Tr.t("Reference · Minimal");reading:Tr.t("Large clock, profile circle and frosted password pill")
            Row {spacing:8
                PillButton{text:Tr.t("Apply reference");onClicked:Config.LockDesignPresetService.apply(Config.LockDesignPresetService.reference())}
            }
        }
    }
    SettingGroup {
        title: Tr.t("Lock screen designer")
        note: Tr.t("Changes are saved live for the lock screen and boot login screen.")
        hint: Tr.t("Drag the clock or profile up and down. Click the password area to edit its size and glass. The preview uses sample password dots and never unlocks your session.")
        bare: true
        SettingRow {
            label:Tr.t("Show bar while locked")
            reading:Tr.t("Turn off for the lock screen alone; the desktop transition still animates")
            ToggleSwitch{checked:SettingsService.lockIslandEnabled;onToggled:checked=>SettingsService.set("lockIslandEnabled",checked)}
        }
        SettingRow {
            label: Tr.t("Edit at full screen size")
            reading: Tr.t("Move elements on your screen with a floating settings panel")
            PillButton {
                objectName: "open-fullscreen-lock-editor"
                text: Tr.t("Open full-screen editor")
                active: true
                onClicked: root.editor.open(root.QsWindow.window?.screen, preview.mode, preview.selected)
            }
        }
        LockDesignPreview { id: preview; Layout.fillWidth: true }
        RowLayout {
            Layout.fillWidth: true
            SegmentedControl {
                options: [
                    { id: "idle", label: Tr.t("Idle") },
                    { id: "password", label: Tr.t("Password") },
                    { id: "error", label: Tr.t("Wrong password") },
                    { id: "caps", label: Tr.t("Caps Lock") }
                ]
                current: preview.mode
                onSelected: id => preview.mode = id
            }
            Item { Layout.fillWidth: true }
            PillButton {
                text: Tr.t("Undo edits")
                onClicked: {
                    if (!root.initial) return
                    for (const key of SettingsService.profileKeys)
                        if (key.startsWith("lock") && !key.startsWith("lockMusic"))
                            SettingsService.set(key, root.initial[key])
                }
            }
        }
        SettingRow {
            label: Tr.t("Boot login screen")
            reading: !LockStyleService.bootInstalled ? Tr.t("Shared login theme is not installed yet")
                : LockStyleService.error ? LockStyleService.error
                : LockStyleService.synced ? Tr.t("Synced · the same design will appear at boot") : Tr.t("Saving…")
            alarm: LockStyleService.error !== ""
        }
    }

    SegmentedControl {
        options: [
            { id: "clock", label: Tr.t("Clock") },
            { id: "profile", label: Tr.t("Profile") },
            { id: "field", label: Tr.t("Password pill") },
            { id: "background", label: Tr.t("Background") }
        ]
        current: preview.selected
        onSelected: id => preview.selected = id
    }

    LockDesignControls {
        Layout.fillWidth: true
        selected: preview.selected
    }
}
