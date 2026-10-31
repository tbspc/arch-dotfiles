import QtQuick
import "../theme"
import "../services"
import "../components"
SettingGroup {
    title:Tr.t("Preset library")
    SettingRow { label:Tr.t("Carousel mode");reading:SettingsService.presetLibraryCarousel?Tr.t("Five previews, with the same sliding animation as the bar changer."):Tr.t("A menu with four previews per row.")
        ToggleSwitch { checked:SettingsService.presetLibraryCarousel;onToggled:checked=>SettingsService.set("presetLibraryCarousel",checked) }
    }
    SettingRow { label:Tr.t("Keyboard navigation");reading:Tr.t("Up/down changes category. Left/right selects a preset. Enter applies it.") }
    SettingRow {label:Tr.t("Full setup transition")
        SegmentedControl {options:[{id:"fade",label:Tr.t("Fade")},{id:"slide",label:Tr.t("Slide")},{id:"bounce",label:Tr.t("Soft spring")},{id:"none",label:Tr.t("Instant")}];current:SettingsService.setupTransitionStyle;onSelected:id=>SettingsService.set("setupTransitionStyle",id)}
    }
    SettingRow {label:Tr.t("Preview setup transition");PillButton {text:Tr.t("Preview");onClicked:SetupPresetService.apply(SetupPresetService.capture())}}
    SettingSlider {label:Tr.t("Setup transition duration");from:100;to:800;unit:" ms";value:SettingsService.setupTransitionDuration;onMoved:value=>SettingsService.set("setupTransitionDuration",Math.round(value))}
    SettingSlider {label:Tr.t("Setup transition movement");from:0;to:70;unit:" px";value:SettingsService.setupTransitionDistance;onMoved:value=>SettingsService.set("setupTransitionDistance",Math.round(value))}
}
