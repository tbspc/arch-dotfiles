import QtQuick
import QtQuick.Layouts
import "../components"
import "../services"
import "../theme"
SettingsSection {
    id:root
    property string selected:"all"
    readonly property var entries:[{id:"all",name:Tr.t("All modules")},{id:"clock",name:Tr.t("Clock")},{id:"date",name:Tr.t("Date")},{id:"workspaces",name:Tr.t("Workspaces")}].concat(ModulePresetService.modules.filter(m=>m.id!=="bar"))
    SettingGroup {
        title:Tr.t("Edit module colours")
        note:Tr.t("Select All modules to change text, icons and backgrounds together, or choose an individual module.")
        SettingRow {
            label:Tr.t("Selection")
            RowLayout {
                spacing:8
                PillButton {text:Tr.t("All modules");onClicked:root.selected="all"}
                ThemedComboBox {model:root.entries;textRole:"name";currentIndex:Math.max(0,model.findIndex(e=>e.id===root.selected));onActivated:index=>root.selected=model[index].id}
            }
        }
    }
    SettingGroup {
        visible:root.selected==="all"
        title:Tr.t("All module colours")
        note:Tr.t("Edit all module colours together. Selecting a theme replaces these colours with that theme’s saved colours or defaults. Element positions and sizes are preserved.")
        SettingRow {label:Tr.t("Use shared colours for all modules");ToggleSwitch {checked:SettingsService.moduleColourSync.enabled;onToggled:value=>SettingsService.setSharedModuleColour("enabled",value)}}
        SettingRow {visible:SettingsService.moduleColourSync.enabled;label:Tr.t("Respect individual module colours");reading:Tr.t("Turn off to use the shared palette everywhere");ToggleSwitch {checked:SettingsService.moduleColourSync.respectIndividual;onToggled:value=>SettingsService.setSharedModuleColour("respectIndividual",value)}}
        SettingsColourRow {visible:SettingsService.moduleColourSync.enabled;shared:true;label:Tr.t("Text and clocks");role:"foreground";fallback:Theme.text}
        SettingsColourRow {visible:SettingsService.moduleColourSync.enabled;shared:true;label:Tr.t("Icons and highlights");role:"accent";fallback:Theme.accent}
        SettingsColourRow {visible:SettingsService.moduleColourSync.enabled;shared:true;label:Tr.t("Secondary text");role:"muted";fallback:Theme.textMuted}
        SettingsColourRow {visible:SettingsService.moduleColourSync.enabled;shared:true;label:Tr.t("Backgrounds");role:"background";fallback:Theme.islandGround}
        Repeater {
            model:SettingsService.moduleColourSync.enabled?[{role:"foregroundBrightness",label:"Text brightness",fallback:100},{role:"accentBrightness",label:"Icon brightness",fallback:100},{role:"mutedBrightness",label:"Secondary text brightness",fallback:70}]:[]
            delegate:SettingSlider {required property var modelData;label:Tr.t(modelData.label);from:0;to:150;unit:"%";value:SettingsService.moduleColourSync[modelData.role]??modelData.fallback;onMoved:value=>SettingsService.setSharedModuleColour(modelData.role,Math.round(value))}
        }
        SettingSlider {visible:SettingsService.moduleColourSync.enabled&&!!SettingsService.moduleColourSync.background;label:Tr.t("Background opacity");from:0;to:100;unit:"%";value:SettingsService.moduleColourSync.backgroundOpacity??100;onMoved:value=>SettingsService.setSharedModuleColour("backgroundOpacity",Math.round(value))}
    }
    SettingGroup {
        visible:root.selected!=="all"
        title:Tr.t("Individual module colours")
        note:Tr.t("Default preserves the module design. Theme accent follows the applied theme, Wallpaper follows the wallpaper, and Hex keeps your colour. Select All modules to allow individual overrides while shared colours are enabled.")
        SettingsColourRow {visible:root.selected!=="date";label:Tr.t("Background");colourId:root.selected;role:"background";fallback:Theme.islandGround}
        SettingsColourRow {label:Tr.t("Text and clock");colourId:root.selected;role:"foreground";fallback:Theme.text}
        SettingsColourRow {visible:root.selected!=="date";label:Tr.t("Icons and highlights");colourId:root.selected;role:"accent";fallback:Theme.accent}
        SettingsColourRow {visible:root.selected!=="date";label:Tr.t("Secondary text");colourId:root.selected;role:"muted";fallback:Theme.textMuted}
        SettingRow {label:Tr.t("Reset this module's colours");PillButton {text:Tr.t("Reset");onClicked:{const next=SettingsService.copy(SettingsService.shellColours);delete next[root.selected];SettingsService.set("shellColours",next)}}}
    }
    WorkspaceColourSettings {visible:root.selected==="workspaces"}
}
