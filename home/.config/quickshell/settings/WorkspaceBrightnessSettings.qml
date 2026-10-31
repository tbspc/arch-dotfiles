import QtQuick
import "../components"
import "../services"
import "../theme"
SettingGroup {
    title:Tr.t("Workspace brightness")
    note:Tr.t("100% keeps your current colours. Lower values darken; higher values brighten. Active workspaces stay unchanged.")
    SettingSlider {label:Tr.t("Empty workspace brightness");from:0;to:200;unit:"%";value:SettingsService.workspaceInactiveBrightness;onMoved:value=>SettingsService.set("workspaceInactiveBrightness",Math.round(value))}
    SettingSlider {label:Tr.t("Workspace with windows brightness");from:0;to:200;unit:"%";value:SettingsService.workspaceOccupiedBrightness;onMoved:value=>SettingsService.set("workspaceOccupiedBrightness",Math.round(value))}
}
