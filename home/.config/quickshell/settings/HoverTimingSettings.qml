import QtQuick
import "../theme"
import "../services"
import "../components"
SettingGroup {
    title:Tr.t("Hover timing")
    note:Tr.t("How long to wait before opening the hover view, and before closing it after the pointer leaves the bar.")
    SettingSlider {label:Tr.t("Hover to open delay");from:0;to:2000;unit:" ms";value:SettingsService.islandHoverOpenDelay;onMoved:value=>SettingsService.set("islandHoverOpenDelay",Math.round(value))}
    SettingSlider {label:Tr.t("Pointer leaves to close delay");from:0;to:2000;unit:" ms";value:SettingsService.islandHoverCloseDelay;onMoved:value=>SettingsService.set("islandHoverCloseDelay",Math.round(value))}
}
