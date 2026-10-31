import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"
import "../components"
SettingGroup {
    id:root
    property string selected:"all"
    property bool advanced:false
    readonly property var values:SettingsService.moduleMotion(selected)
    readonly property var entries:[{id:"all",name:Tr.t("All modules")},{id:"bar",name:Tr.t("Bar / Island")},{id:"summary",name:Tr.t("Hover / calendar & media")}].concat(ModulePresetService.modules.filter(m=>m.id!=="bar"))
    title:Tr.t("Module opening and closing")
    note:Tr.t("Follow the shell’s speed, curve and fades, or turn following off for an independent override. Your custom values are retained. The centred closing handoff and live hover collapse are preserved.")
    SettingRow {label:Tr.t("Edit animations for");ThemedComboBox {model:root.entries;textRole:"name";currentIndex:Math.max(0,model.findIndex(m=>m.id===root.selected));onActivated:index=>root.selected=model[index].id}}
    SettingRow {
        label:Tr.t("Follow shell animations")
        reading:root.values.followShell?Tr.t("Uses the shell’s speed, curve and fades. No extra speed multiplier."):Tr.t("Custom: this target has its own style and speed.")
        ToggleSwitch {checked:root.values.followShell;onToggled:value=>SettingsService.setModuleMotion(root.selected,"followShell",value)}
    }
    Repeater {
        model:[SettingsService.moduleAnimationPresets.slice(0,3),SettingsService.moduleAnimationPresets.slice(3)]
        delegate:SettingTiles {
            id:motionRow
            required property var modelData
            label:""
            Repeater {
                model:motionRow.modelData
                delegate:PreviewTile {
                    id:tile
                    required property var modelData
                    stageHeight:74;caption:Tr.t(modelData.label)
                    selected:root.values.preset===modelData.id
                    onPicked:SettingsService.setModuleMotion(root.selected,"preset",modelData.id)
                    ModuleAnimationPreview {anchors.centerIn:parent;preset:tile.modelData;speed:root.values.speed;delay:root.values.axisDelay}
                }
            }
        }
    }
    SettingRow {visible:!root.values.followShell;label:Tr.t("Expansion easing");ThemedComboBox {model:[{id:"preset",name:Tr.t("Use preset")},{id:"OutCubic",name:Tr.t("Smooth")},{id:"OutQuint",name:Tr.t("Soft")},{id:"InOutCubic",name:Tr.t("Cinematic")},{id:"OutSine",name:Tr.t("Gentle")}];textRole:"name";currentIndex:Math.max(0,model.findIndex(m=>m.id===root.values.curve));onActivated:index=>SettingsService.setModuleMotion(root.selected,"curve",model[index].id)}}
    SettingSlider {visible:!root.values.followShell&&!root.values.exactDuration;label:Tr.t("Opening speed");from:50;to:200;unit:"%";value:root.values.speed;onMoved:value=>SettingsService.setModuleMotion(root.selected,"speed",Math.round(value))}
    SettingSlider {visible:!root.values.followShell&&["width-first","height-first"].includes(root.values.preset);label:Tr.t("Delay between width and height");from:0;to:60;unit:"%";value:root.values.axisDelay;onMoved:value=>SettingsService.setModuleMotion(root.selected,"axisDelay",Math.round(value))}
    SettingSlider {visible:!root.values.followShell;label:Tr.t("Opening content fade");from:0;to:200;unit:"%";value:root.values.contentFade;onMoved:value=>SettingsService.setModuleMotion(root.selected,"contentFade",Math.round(value))}
    SettingRow {visible:!root.values.followShell;label:Tr.t("Match opening and closing");reading:Tr.t("Use the same style, easing and speed in reverse.");ToggleSwitch {checked:root.values.matchClosing;onToggled:value=>SettingsService.setModuleMotion(root.selected,"matchClosing",value)}}
    SettingRow {visible:!root.values.followShell&&!root.values.matchClosing;label:Tr.t("Closing style");ThemedComboBox {model:SettingsService.moduleAnimationPresets;textRole:"label";currentIndex:Math.max(0,model.findIndex(m=>m.id===root.values.closePreset));onActivated:index=>SettingsService.setModuleMotion(root.selected,"closePreset",model[index].id)}}
    SettingRow {visible:!root.values.followShell&&!root.values.matchClosing;label:Tr.t("Closing easing");ThemedComboBox {model:[{id:"preset",name:Tr.t("Use preset")},{id:"OutCubic",name:Tr.t("Smooth")},{id:"OutQuint",name:Tr.t("Soft")},{id:"InOutCubic",name:Tr.t("Cinematic")},{id:"OutSine",name:Tr.t("Gentle")}];textRole:"name";currentIndex:Math.max(0,model.findIndex(m=>m.id===root.values.closeCurve));onActivated:index=>SettingsService.setModuleMotion(root.selected,"closeCurve",model[index].id)}}
    SettingSlider {visible:!root.values.followShell&&!root.values.matchClosing&&!root.values.exactDuration;label:Tr.t("Closing speed");from:50;to:200;unit:"%";value:root.values.closeSpeed;onMoved:value=>SettingsService.setModuleMotion(root.selected,"closeSpeed",Math.round(value))}
    SettingSlider {visible:!root.values.followShell;label:Tr.t("Closing content fade");from:0;to:200;unit:"%";value:root.values.closeFade;onMoved:value=>SettingsService.setModuleMotion(root.selected,"closeFade",Math.round(value))}
    SettingSlider {label:Tr.t("Bar icons fade in");from:0;to:300;unit:" ms";value:root.values.swapDuration;onMoved:value=>SettingsService.setModuleMotion(root.selected,"swapDuration",Math.round(value))}
    SettingSlider {visible:!root.values.followShell&&["all","bar","summary"].includes(root.selected);label:Tr.t("Hover view collapse speed");from:50;to:200;unit:"%";value:root.values.hoverCloseSpeed;onMoved:value=>SettingsService.setModuleMotion(root.selected,"hoverCloseSpeed",Math.round(value))}
    SettingSlider {visible:!root.values.followShell&&["all","bar","summary"].includes(root.selected);label:Tr.t("Hover view collapse bounce");from:0;to:120;unit:"%";value:root.values.hoverCloseBounce;onMoved:value=>SettingsService.setModuleMotion(root.selected,"hoverCloseBounce",Math.round(value))}
    SettingRow {visible:["all","bar"].includes(root.selected);label:Tr.t("Bounce bar contents");reading:Tr.t("Gently bounce the clock and enabled icons independently of the panel shape.");ToggleSwitch {checked:root.values.barItemsBounce;onToggled:value=>SettingsService.setModuleMotion(root.selected,"barItemsBounce",value)}}
    SettingSlider {visible:["all","bar"].includes(root.selected)&&root.values.barItemsBounce;label:Tr.t("Contents bounce strength");from:0;to:100;unit:"%";value:root.values.barItemsBounceStrength;onMoved:value=>SettingsService.setModuleMotion(root.selected,"barItemsBounceStrength",Math.round(value))}
    SettingSlider {visible:["all","bar"].includes(root.selected)&&root.values.barItemsBounce;label:Tr.t("Contents bounce duration");from:120;to:900;unit:" ms";value:root.values.barItemsBounceDuration;onMoved:value=>SettingsService.setModuleMotion(root.selected,"barItemsBounceDuration",Math.round(value))}
    SettingRow {visible:!root.values.followShell;label:Tr.t("Start closing resize immediately");reading:Tr.t("Fade the contents and resize together, without an initial hold.");ToggleSwitch {checked:root.values.closeParallel;onToggled:value=>SettingsService.setModuleMotion(root.selected,"closeParallel",value)}}
    SettingRow {visible:!root.values.followShell;label:Tr.t("Advanced smoothing");ToggleSwitch {checked:root.advanced;onToggled:value=>root.advanced=value}}
    SettingRow {visible:root.advanced&&!root.values.followShell;label:Tr.t("Use exact durations");reading:Tr.t("Replaces the speed percentages with direct timing.");ToggleSwitch {checked:root.values.exactDuration;onToggled:value=>SettingsService.setModuleMotion(root.selected,"exactDuration",value)}}
    SettingSlider {visible:root.advanced&&!root.values.followShell&&root.values.exactDuration;label:Tr.t("Opening duration");from:120;to:1400;unit:" ms";value:root.values.openDuration;onMoved:value=>SettingsService.setModuleMotion(root.selected,"openDuration",Math.round(value))}
    SettingSlider {visible:root.advanced&&!root.values.followShell&&root.values.exactDuration&&!root.values.matchClosing;label:Tr.t("Closing duration");from:120;to:1400;unit:" ms";value:root.values.closeDuration;onMoved:value=>SettingsService.setModuleMotion(root.selected,"closeDuration",Math.round(value))}
    SettingRow {visible:root.advanced&&!root.values.followShell;label:Tr.t("Custom expansion curve");ToggleSwitch {checked:root.values.customCurve;onToggled:value=>SettingsService.setModuleMotion(root.selected,"customCurve",value)}}
    Repeater {
        model:root.advanced&&!root.values.followShell&&root.values.customCurve?[{key:"bezierX1",name:"Curve start timing",max:100},{key:"bezierY1",name:"Curve start response",max:140},{key:"bezierX2",name:"Curve end timing",max:100},{key:"bezierY2",name:"Curve end response",max:140}]:[]
        delegate:SettingSlider {required property var modelData;label:Tr.t(modelData.name);from:0;to:modelData.max;unit:"%";value:root.values[modelData.key];onMoved:value=>SettingsService.setModuleMotion(root.selected,modelData.key,Math.round(value))}
    }
    SettingRow {visible:root.selected!=="all";label:Tr.t("Use shared animation again");PillButton {text:Tr.t("Reset");onClicked:{const next=SettingsService.copy(SettingsService.moduleAnimations);delete next[root.selected];SettingsService.set("moduleAnimations",next)}}}
}
