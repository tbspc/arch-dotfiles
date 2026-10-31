import QtQuick
import "../components"
import "../theme"
import "../services"
SettingGroup {
    id:root
    property bool advanced:false
    readonly property var values:Object.assign({},SettingsService.pristine.shellSpring,SettingsService.shellSpring)
    title:Tr.t("Video reference motion")
    note:Tr.t("The panel and its clock, workspaces and indicators share a native animation clock. Times are measured from the supplied recording; no UI layout or colours are replaced.")
    SettingRow {label:Tr.t("Use reference spring motion");ToggleSwitch {checked:SettingsService.shellSpring.enabled;onToggled:value=>SettingsService.setShellSpring("enabled",value)}}
    SettingRow {visible:SettingsService.shellSpring.enabled;label:Tr.t("New module video path");ToggleSwitch {checked:root.values.moduleVideo===true;onToggled:value=>SettingsService.setShellSpring("moduleVideo",value)}}
    SettingRow {visible:SettingsService.shellSpring.enabled;label:Tr.t("Motion path");SegmentedControl {options:[{id:"traced",label:Tr.t("Video trace")},{id:"spring",label:Tr.t("Spring")}];current:root.values.mode;onSelected:id=>SettingsService.setShellSpring("mode",id)}}
    SettingSlider {visible:SettingsService.shellSpring.enabled&&root.values.mode!=="traced";label:Tr.t("Spring damping");from:45;to:99;unit:"%";value:SettingsService.shellSpring.damping;onMoved:value=>SettingsService.setShellSpring("damping",Math.round(value))}
    Repeater {
        model:SettingsService.shellSpring.enabled?[{key:"openDuration",label:"Hover opening duration"},{key:"panelDuration",label:"Module opening duration"},{key:"closeDuration",label:"Hover closing duration"},{key:"moduleCloseDuration",label:"Module closing duration"},{key:"switchDuration",label:"Switch between modules"},{key:"wideDuration",label:"Switch between wide panels"},{key:"verticalDuration",label:"Switch between tall panels"}]:[]
        delegate:SettingSlider {required property var modelData;label:Tr.t(modelData.label);from:120;to:900;unit:" ms";value:modelData.key==="moduleCloseDuration"?(root.values.moduleCloseDuration||root.values.closeDuration):root.values[modelData.key];onMoved:value=>SettingsService.setShellSpring(modelData.key,Math.round(value))}
    }
    SettingRow {visible:SettingsService.shellSpring.enabled;label:Tr.t("Stagger bar indicators");reading:Tr.t("The workspace marks fan out separately and the status icons follow with a slight spring lag.");ToggleSwitch {checked:SettingsService.shellSpring.movingItems;onToggled:value=>SettingsService.setShellSpring("movingItems",value)}}
    SettingSlider {visible:SettingsService.shellSpring.enabled&&SettingsService.shellSpring.movingItems;label:Tr.t("Delay between indicators");from:0;to:40;unit:" ms";value:SettingsService.shellSpring.itemStagger;onMoved:value=>SettingsService.setShellSpring("itemStagger",Math.round(value))}
    SettingRow {visible:SettingsService.shellSpring.enabled;label:Tr.t("Advanced spring controls");ToggleSwitch {checked:root.advanced;onToggled:value=>root.advanced=value}}
    Repeater {
        model:SettingsService.shellSpring.enabled&&root.advanced&&root.values.mode!=="traced"?[{key:"openFrequency",label:"Hover spring response"},{key:"panelFrequency",label:"Module spring response"},{key:"closeFrequency",label:"Closing spring response"}]:[]
        delegate:SettingSlider {required property var modelData;label:Tr.t(modelData.label);from:10;to:45;value:root.values[modelData.key];onMoved:value=>SettingsService.setShellSpring(modelData.key,Math.round(value))}
    }
    Repeater {
        model:SettingsService.shellSpring.enabled&&root.advanced?[{key:"closeContentFade",label:"Closing content crossfade",max:300},{key:"restFade",label:"Resting bar fade on opening",max:200},{key:"contentDelay",label:"Module contents reveal delay",max:200},{key:"contentFade",label:"Module contents fade duration",max:300}]:[]
        delegate:SettingSlider {required property var modelData;label:Tr.t(modelData.label);from:0;to:modelData.max;unit:" ms";value:root.values[modelData.key];onMoved:value=>SettingsService.setShellSpring(modelData.key,Math.round(value))}
    }
    SettingRow {visible:SettingsService.shellSpring.enabled;label:Tr.t("Restore measured video timing");PillButton {text:Tr.t("Reset reference");onClicked:SettingsService.applyShellMotionPreset(Theme.motionPresets.find(p=>p.id===(root.values.moduleVideo?"video-modules-safe":"video-reference")))}}
}
