import QtQuick
import "../components"
import "../services"
import "../theme"
SettingGroup {
    property bool showToggle:true
    title:Tr.t("Workspace glow")
    note:Tr.t("The glow follows the active workspace colour. These controls apply to the bar and workspace chip.")
    SettingRow {visible:showToggle;label:Tr.t("Active workspace glow");ToggleSwitch {checked:SettingsService.islandWorkspacesGlow;onToggled:value=>SettingsService.set("islandWorkspacesGlow",value)}}
    SettingSlider {label:Tr.t("Range");from:0;to:64;unit:" px";value:SettingsService.workspaceGlowRange;onMoved:value=>SettingsService.set("workspaceGlowRange",Math.round(value))}
    SettingSlider {label:Tr.t("Intensity");from:0;to:100;unit:"%";value:SettingsService.workspaceGlowIntensity;onMoved:value=>SettingsService.set("workspaceGlowIntensity",Math.round(value))}
    SettingSlider {label:Tr.t("Spread");from:100;to:180;unit:"%";value:SettingsService.workspaceGlowSpread;onMoved:value=>SettingsService.set("workspaceGlowSpread",Math.round(value))}
}
