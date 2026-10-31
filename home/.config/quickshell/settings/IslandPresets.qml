import QtQuick
import Quickshell
import QtQuick.Layouts
import "../theme"
import "../services"
import "../components"

SettingsSection {
    id: root
    property string presetName: ""
    property string message: ""
    property string deleting: ""
    property string category: SettingsService.islandChipsEnabled ? "chips" : SettingsService.notched ? "notched" : "floating"
    property string subcategory: "all"
    readonly property var savedSelection: IslandPresetService.select(IslandPresetService.saved, category, subcategory)
    readonly property var designSelection: IslandPresetService.select(IslandPresetService.designs, category, subcategory)

    SettingGroup {
        title: Tr.t("Save your island")
        note: Tr.t("Keep the current layout, clock, indicators and interaction settings as a named preset.")
        hint: Tr.t("Presets use your current wallpaper, colors and bar surface. Applying one changes Island settings only. Saved presets stay as they were until you choose Update.")

        SettingField {
            label: Tr.t("Preset name")
            placeholder: Tr.t("My island")
            value: root.presetName
            onEdited: value => root.presetName = value
        }
        SettingRow {
            label: root.message || Tr.t("Save the current configuration")
            Row {
                spacing: 8
                PillButton {
                    visible: IslandPresetService.previous !== null
                    text: Tr.t("Undo apply")
                    onClicked: { IslandPresetService.undo(); root.message = Tr.t("Previous island restored") }
                }
                PillButton {
                    text: Tr.t("Save current")
                    active: true
                    enabled: IslandPresetService.ready && SettingsService.arrived
                    onClicked: {
                        if (IslandPresetService.save(root.presetName)) {
                            root.presetName = ""
                            root.message = Tr.t("Island preset saved")
                        }
                    }
                }
            }
        }
    }

    SettingRow {
        label: Tr.t("Built-in designs")
        PillButton { text:Tr.t("Restore built-in presets"); onClicked:IslandPresetService.restoreDesigns() }
    }
    SettingGroup {
        title: Tr.t("Browse presets")
        SettingRow {
            label: Tr.t("Category")
            SegmentedControl {
                options: IslandPresetService.categories.map(item => ({id:item.id,label:Tr.t(item.name)}))
                current: root.category
                onSelected: id => { root.category=id; root.deleting="" }
            }
        }
        SettingRow {
            label: Tr.t("Style")
            SegmentedControl {
                options: [{id:"all",label:Tr.t("All")}].concat(IslandPresetService.subcategories.map(item => ({id:item.id,label:Tr.t(item.name)})))
                current: root.subcategory
                onSelected: id => { root.subcategory=id; root.deleting="" }
            }
        }
    }

    component PresetCard: Rectangle {
        id: card
        required property var preset
        property bool editable: false
        readonly property bool applied: IslandPresetService.matches(preset.values)
        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + 24
        radius: Theme.radiusMedium
        color: Theme.colourIn(QsWindow.window,"fieldBackground",Theme.surface)
        border.width: 1
        border.color: applied ? Theme.accentIn(QsWindow.window) : Theme.colourIn(QsWindow.window,"borderColor",Theme.border)

        ColumnLayout {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 10
            IslandPresetPreview {
                Layout.fillWidth: true
                values: card.preset.values
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: card.preset.name
                    font.family: Theme.fontIn(QsWindow.window)
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    color: Theme.textIn(QsWindow.window)
                    elide: Text.ElideRight
                }
                Text {
                    visible: card.applied
                    text: Tr.t("In use")
                    color: Theme.accentIn(QsWindow.window)
                    font.family: Theme.fontIn(QsWindow.window)
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
            Text {
                Layout.fillWidth: true
                text: card.preset.description || Tr.t("Your saved island configuration")
                wrapMode: Text.WordWrap
                font.family: Theme.fontIn(QsWindow.window)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.mutedIn(QsWindow.window)
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                PillButton {
                    text: Tr.t("Apply")
                    active: card.applied
                    enabled: IslandPresetService.ready
                    onClicked: {
                        if (IslandPresetService.apply(card.preset.values))
                            root.message = Tr.t("Applied") + " · " + card.preset.name
                    }
                }
                Item { Layout.fillWidth: true }
                PillButton {
                    visible: card.editable
                    text: Tr.t("Update")
                    onClicked: {
                        IslandPresetService.update(card.preset.id)
                        root.message = Tr.t("Updated") + " · " + card.preset.name
                    }
                }
                PillButton {
                    visible: card.editable
                    text: root.deleting === card.preset.id ? Tr.t("Confirm delete") : Tr.t("Delete")
                    onClicked: {
                        if (root.deleting === card.preset.id) {
                            IslandPresetService.remove(card.preset.id)
                            root.deleting = ""
                        } else {
                            root.deleting = card.preset.id
                        }
                    }
                }
            }
        }
    }

    SettingGroup {
        title: Tr.t("Your presets")
        note: Tr.t("My current island preserves the setup you had before presets were added.")
        bare: true
        GridLayout {
            Layout.fillWidth: true
            columns: width >= 680 ? 2 : 1
            columnSpacing: 12
            rowSpacing: 12
            Repeater {
                model: root.savedSelection
                PresetCard {
                    required property var modelData
                    preset: modelData
                    editable: true
                }
            }
        }
        Text {
            visible: root.savedSelection.length === 0
            text: Tr.t("No saved presets in this group. Save your current island to add one.")
            font.family: Theme.fontIn(QsWindow.window)
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.mutedIn(QsWindow.window)
        }
    }
    SettingGroup {
        title: Tr.t("Designs to try")
        note: Tr.t("Apply a design, adjust it in the other Island tabs, then save your own version.")
        bare: true
        GridLayout {
            Layout.fillWidth: true
            columns: width >= 680 ? 2 : 1
            columnSpacing: 12
            rowSpacing: 12
            Repeater {
                model: root.designSelection
                PresetCard {
                    required property var modelData
                    preset: modelData
                    editable: true
                }
            }
        }
    }
}
