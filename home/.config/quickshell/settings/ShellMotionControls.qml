import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"
import "../components"
SettingsSection {
    id:root
    property bool advanced:false
    ReferenceMotionControls {}
    SettingGroup {
        title:Tr.t("Standard easing & fades")
        note:Tr.t("Global speed also applies to the reference spring. Standard curve controls apply when reference spring motion is off.")
        SettingSlider {label:Tr.t("Animation speed");from:50;to:200;unit:"%";value:SettingsService.motionScale>0?Math.round(10000/SettingsService.motionScale):100;onMoved:value=>SettingsService.set("motionScale",Math.round(10000/value))}
        SettingRow {visible:!SettingsService.shellSpring.enabled;label:Tr.t("Animation curve");ThemedComboBox {model:Theme.easingCurves;textRole:"label";currentIndex:Math.max(0,model.findIndex(m=>m.id===SettingsService.motionCurve));onActivated:index=>SettingsService.set("motionCurve",model[index].id)}}
        SettingSlider {visible:!SettingsService.shellSpring.enabled;label:Tr.t("Movement distance");from:0;to:200;unit:"%";value:SettingsService.shellMovement;onMoved:value=>SettingsService.set("shellMovement",Math.round(value))}
        SettingSlider {visible:!SettingsService.shellSpring.enabled;label:Tr.t("Bounce strength");from:0;to:200;unit:"%";value:SettingsService.shellBounceStrength;onMoved:value=>SettingsService.set("shellBounceStrength",Math.round(value))}
        SettingSlider {visible:!SettingsService.shellSpring.enabled;label:Tr.t("Bounce frequency");from:50;to:200;unit:"%";value:SettingsService.shellBounceCycles;onMoved:value=>SettingsService.set("shellBounceCycles",Math.round(value))}
        SettingSlider {visible:!SettingsService.shellSpring.enabled;label:Tr.t("Fade duration");from:0;to:200;unit:"%";value:SettingsService.shellFadeDuration;onMoved:value=>SettingsService.set("shellFadeDuration",Math.round(value))}
        SettingRow {visible:!SettingsService.shellSpring.enabled;label:Tr.t("Closing sequence");SegmentedControl {options:[{id:"parallel",label:Tr.t("Immediate")},{id:"staged",label:Tr.t("Content first")}];current:SettingsService.shellCloseMode;onSelected:id=>SettingsService.set("shellCloseMode",id)}}
        SettingRow {visible:!SettingsService.shellSpring.enabled;label:Tr.t("Advanced smoothing");ToggleSwitch {checked:root.advanced;onToggled:value=>root.advanced=value}}
        SettingSlider {visible:root.advanced&&!SettingsService.shellSpring.enabled;label:Tr.t("Expansion duration");reading:Tr.t("Base duration before applying the global speed.");from:180;to:1200;unit:" ms";value:SettingsService.shellExpandDuration;onMoved:value=>SettingsService.set("shellExpandDuration",Math.round(value))}
        SettingSlider {visible:root.advanced&&!SettingsService.shellSpring.enabled;label:Tr.t("Shape spring strength");from:0;to:120;unit:"%";value:SettingsService.shellShapeSpring;onMoved:value=>SettingsService.set("shellShapeSpring",Math.round(value))}
        SettingSlider {visible:root.advanced&&!SettingsService.shellSpring.enabled;label:Tr.t("Bounce damping");from:30;to:300;unit:"%";value:SettingsService.shellBounceDamping;onMoved:value=>SettingsService.set("shellBounceDamping",Math.round(value))}
        SettingSlider {visible:root.advanced&&!SettingsService.shellSpring.enabled;label:Tr.t("Fade rise distance");from:0;to:40;unit:" px";value:SettingsService.shellFadeDistance;onMoved:value=>SettingsService.set("shellFadeDistance",Math.round(value))}
        SettingSlider {visible:root.advanced&&!SettingsService.shellSpring.enabled;label:Tr.t("Fade zoom amount");from:0;to:12;unit:"%";value:SettingsService.shellZoomAmount;onMoved:value=>SettingsService.set("shellZoomAmount",Math.round(value))}
        SettingRow {visible:root.advanced&&!SettingsService.shellSpring.enabled;label:Tr.t("Custom expansion curve");ToggleSwitch {checked:SettingsService.shellBezier.enabled;onToggled:value=>SettingsService.setShellBezier("enabled",value)}}
        Repeater {
            model:root.advanced&&!SettingsService.shellSpring.enabled&&SettingsService.shellBezier.enabled?[{key:"x1",name:"Curve start timing",max:100},{key:"y1",name:"Curve start response",max:140},{key:"x2",name:"Curve end timing",max:100},{key:"y2",name:"Curve end response",max:140}]:[]
            delegate:SettingSlider {required property var modelData;label:Tr.t(modelData.name);from:0;to:modelData.max;unit:"%";value:SettingsService.shellBezier[modelData.key];onMoved:value=>SettingsService.setShellBezier(modelData.key,Math.round(value))}
        }
    }
}
