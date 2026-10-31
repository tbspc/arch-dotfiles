import QtQuick
import "../services"
import "../components"
import "../theme"
SettingGroup {
    readonly property var values:Object.assign({},SettingsService.pristine.windowMotion,SettingsService.windowMotion)
    title:Tr.t("Window animation controls")
    SettingSlider {label:Tr.t("Speed");from:50;to:200;unit:"%";value:SettingsService.windowAnimationSpeed;onMoved:value=>SettingsService.set("windowAnimationSpeed",Math.round(value))}
    SettingSlider {label:Tr.t("Expansion amount");reading:Tr.t("For presets that scale windows when opening.");from:0;to:180;unit:"%";value:SettingsService.windowAnimationAmount;onMoved:value=>SettingsService.set("windowAnimationAmount",Math.round(value))}
    SettingSlider {label:Tr.t("Spring strength");reading:Tr.t("Controls the rebound in spring presets.");from:0;to:160;unit:"%";value:SettingsService.windowAnimationBounce;onMoved:value=>SettingsService.set("windowAnimationBounce",Math.round(value))}
    SettingRow {label:Tr.t("Workspace movement")
        SegmentedControl {options:[{id:"preset",label:Tr.t("Preset")},{id:"slide",label:Tr.t("Slide")},{id:"fade",label:Tr.t("Fade")}];current:SettingsService.windowWorkspaceMotion;onSelected:id=>SettingsService.set("windowWorkspaceMotion",id)}
    }
    SettingRow {label:Tr.t("Window easing");ThemedComboBox {model:[{id:"preset",name:Tr.t("Use preset")},{id:"smooth",name:Tr.t("Smooth")},{id:"gentle",name:Tr.t("Gentle")},{id:"cinematic",name:Tr.t("Cinematic")},{id:"spring",name:Tr.t("Soft spring")},{id:"linear",name:Tr.t("Linear")}];textRole:"name";currentIndex:Math.max(0,model.findIndex(m=>m.id===values.curve));onActivated:index=>SettingsService.setWindowMotion("curve",model[index].id)}}
    Repeater {
        model:[{key:"openStyle",label:"Opening style"},{key:"closeStyle",label:"Closing style"}]
        delegate:SettingRow {
            required property var modelData
            label:Tr.t(modelData.label)
            SegmentedControl {options:[{id:"preset",label:Tr.t("Preset")},{id:"popin",label:Tr.t("Expand")},{id:"slide",label:Tr.t("Slide")},{id:"fade",label:Tr.t("Fade")}];current:SettingsService.windowMotion[modelData.key]||"preset";onSelected:id=>SettingsService.setWindowMotion(modelData.key,id)}
        }
    }
    Repeater {
        model:[{key:"openSpeed",label:"Opening speed"},{key:"closeSpeed",label:"Closing speed"},{key:"moveSpeed",label:"Moving and resizing speed"},{key:"workspaceSpeed",label:"Workspace speed"},{key:"fadeSpeed",label:"Opacity fade speed"}]
        delegate:SettingSlider {required property var modelData;label:Tr.t(modelData.label);from:50;to:200;unit:"%";value:SettingsService.windowMotion[modelData.key]??100;onMoved:value=>SettingsService.setWindowMotion(modelData.key,Math.round(value))}
    }

}
