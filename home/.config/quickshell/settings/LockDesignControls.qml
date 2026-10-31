import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"
import "../components"

SettingsSection {
    id: root
    property string selected: "clock"
    component DesignSlider: SettingSlider {
        required property string setting
        value: SettingsService[setting]
        onMoved: value => SettingsService.set(setting, Math.round(value))
    }

    SettingGroup {
        visible: root.selected === "clock"
        title: Tr.t("Clock and date")
        SettingRow {
            label: Tr.t("Clock style")
            SegmentedControl {
                options: [{id: "inline", label: Tr.t("Inline")}, {id: "stacked", label: Tr.t("Stacked")}, {id: "flip", label: Tr.t("Flip")}]
                current: SettingsService.lockClock
                onSelected: id => SettingsService.set("lockClock", id)
            }
        }
        SettingRow {
            label: Tr.t("Time format")
            SegmentedControl {
                options: [{id: "HH:mm", label: Tr.t("24-hour")}, {id: "hh:mm AP", label: Tr.t("12-hour")}]
                current: SettingsService.lockTimeFormat
                onSelected: id => SettingsService.set("lockTimeFormat", id)
            }
        }
        SettingRow {
            label: Tr.t("Typeface")
            SegmentedControl {
                options: [{id: "rounded", label: Tr.t("Rounded")}, {id:"sf-display",label:"SF Pro Display"}, {id: "sans", label: Tr.t("Sans")}, {id: "mono", label: Tr.t("Mono")}]
                current: SettingsService.lockFont
                onSelected: id => SettingsService.set("lockFont", id)
            }
        }
        SettingRow {
            label: Tr.t("Text color")
            SegmentedControl {
                options: [{id: "white", label: Tr.t("White")}, {id: "accent", label: Tr.t("Theme accent")}]
                current: SettingsService.lockInk
                onSelected: id => SettingsService.set("lockInk", id)
            }
        }
        DesignSlider { setting: "lockClockSize"; label: Tr.t("Clock size"); from: 60; to: 260; unit: " px" }
        DesignSlider { setting: "lockClockTop"; label: Tr.t("Distance from top"); from: 0; to: 320; unit: " px" }
        DesignSlider { setting: "lockClockOpacity"; label: Tr.t("Clock opacity"); from: 20; to: 100; unit: "%" }
        DesignSlider { setting: "lockClockShadow"; label: Tr.t("Clock shadow"); from: 0; to: 100; unit: "%" }
        SettingRow {
            label: Tr.t("Show date")
            ToggleSwitch { checked: SettingsService.lockShowsDate; onToggled: checked => SettingsService.set("lockShowsDate", checked) }
        }
        DesignSlider { setting: "lockDateSize"; label: Tr.t("Date size"); from: 10; to: 40; unit: " px" }
        DesignSlider { setting: "lockDateOpacity"; label: Tr.t("Date opacity"); from: 10; to: 100; unit: "%" }
    }
    SettingGroup {
        visible: root.selected === "profile"
        title: Tr.t("Profile and spacing")
        SettingRow{label:Tr.t("Profile style");SegmentedControl{options:[{id:"original",label:Tr.t("Account photo")},{id:"reference",label:Tr.t("Reference symbol")}];current:SettingsService.lockDesign;onSelected:id=>SettingsService.set("lockDesign",id)}}
        note: Tr.t("Change your picture and name in Session account settings.")
        DesignSlider { setting: "lockAvatarSize"; label: Tr.t("Avatar size"); from: 24; to: 100; unit: " px" }
        DesignSlider { setting: "lockNameSize"; label: Tr.t("Name size"); from: 9; to: 24; unit: " px" }
        DesignSlider { setting: "lockAccountBottom"; label: Tr.t("Distance from bottom"); from: 0; to: 360; unit: " px" }
        DesignSlider { setting: "lockProfileGap"; label: Tr.t("Avatar to name gap"); from: 0; to: 32; unit: " px" }
        DesignSlider { setting: "lockPromptGap"; label: Tr.t("Name to password gap"); from: 4; to: 60; unit: " px" }
        SettingRow {
            label: Tr.t("Show idle hint")
            ToggleSwitch { checked: SettingsService.lockHint; onToggled: checked => SettingsService.set("lockHint", checked) }
        }
        SettingField { label: Tr.t("Idle hint"); value: SettingsService.lockIdleHint; onEdited: value => SettingsService.set("lockIdleHint", value.slice(0, 100)) }
    }
    SettingGroup {
        visible: root.selected === "field"
        title: Tr.t("Password pill")
        SettingRow {label:Tr.t("Material");SegmentedControl {options:[{id:"classic",label:Tr.t("Original")},{id:"tahoe",label:Tr.t("MacShell Liquid Glass")}];current:SettingsService.lockFieldMaterial;onSelected:id=>SettingsService.set("lockFieldMaterial",id)}}
        DesignSlider {visible:SettingsService.lockFieldMaterial==="tahoe";setting:"lockGlassRefraction";label:Tr.t("Refraction");from:0;to:180;unit:"%"}
        DesignSlider {visible:SettingsService.lockFieldMaterial==="tahoe";setting:"lockGlassBlur";label:Tr.t("Blur");from:0;to:22;unit:" px"}
        DesignSlider {visible:SettingsService.lockFieldMaterial==="tahoe";setting:"lockGlassTint";label:Tr.t("Tint / opacity");from:0;to:100;unit:"%"}
        DesignSlider {visible:SettingsService.lockFieldMaterial==="tahoe";setting:"lockGlassShine";label:Tr.t("Edge light");from:0;to:100;unit:"%"}
        DesignSlider { setting: "lockFieldWidth"; label: Tr.t("Width"); from: 140; to: 400; unit: " px" }
        DesignSlider { setting: "lockFieldHeight"; label: Tr.t("Height"); from: 24; to: 52; unit: " px" }
        DesignSlider { setting: "lockFieldOpacity"; label: Tr.t("Glass opacity"); from: 0; to: 70; unit: "%" }
        DesignSlider { setting: "lockFieldBorderOpacity"; label: Tr.t("Edge light"); from: 0; to: 100; unit: "%" }
        SettingField { label: Tr.t("Placeholder"); value: SettingsService.lockPlaceholder; onEdited: value => SettingsService.set("lockPlaceholder", value.slice(0, 80)) }
    }
    SettingGroup {
        visible: root.selected === "background"
        title: Tr.t("Wallpaper and status")
        note: Tr.t("The current wallpaper is shared with the boot login screen automatically.")
        SettingRow {
            label:Tr.t("Background")
            reading:Tr.t("Desktop captures your open windows when locking; boot login uses wallpaper")
            SegmentedControl{options:[{id:"wallpaper",label:Tr.t("Wallpaper")},{id:"desktop",label:Tr.t("Desktop")}];current:SettingsService.lockBackdrop;onSelected:id=>SettingsService.set("lockBackdrop",id)}
        }
        DesignSlider { setting: "lockBlur"; label: Tr.t("Wallpaper blur"); from: 0; to: 256; unit: " px" }
        DesignSlider {setting:"lockVibrance";label:Tr.t("Vibrance change");from:-100;to:100;unit:"%"}
        DesignSlider { setting: "lockExtraBlur"; label: Tr.t("Extra blur while typing"); from: 0; to: 150; unit: "%" }
        DesignSlider { setting: "lockDim"; label: Tr.t("Darkening"); from: 0; to: 60; unit: "%" }
        SettingRow {
            label: Tr.t("Status icons")
            reading: Tr.t("Battery at boot; battery and Wi-Fi while locked")
            ToggleSwitch { checked: SettingsService.lockStatus; onToggled: checked => SettingsService.set("lockStatus", checked) }
        }
    }
    SettingGroup {
        visible: root.selected === "background"
        title: Tr.t("Bar on the lock screen")
        SettingRow {
            label: Tr.t("Show bar while locked")
            reading:Tr.t("Off keeps the full-screen transition without the extra bar or lock symbol")
            ToggleSwitch {
                checked: SettingsService.lockIslandEnabled
                onToggled: checked => {
                    SettingsService.set("lockIslandEnabled",checked)
                }
            }
        }
    }

}
