import QtQuick
import "../services"
import "../theme"

SettingGroup {
    id:root
    readonly property bool barTarget:SettingsService.surfaceStyle==="tahoe"
    readonly property bool windowTarget:SettingsService.macGlassFileDialogs||SettingsService.macGlassNautilus||SettingsService.macGlassWindows||SettingsService.terminalGround==="tahoe"||(SettingsService.macGlassSettings&&SettingsDesignService.style.opaque!==true)
    readonly property bool activeTarget:SettingsService.surfaceStyle==="tahoe"||windowTarget
    title:Tr.t("MacShell Liquid Glass")
    note:Tr.t("Live compositor refraction, blur and a soft white rim. Window glass is visible through transparent app backgrounds; opaque apps keep their own appearance.")
    readonly property bool editingBar:SettingsService.macGlassProfileTarget==="bar"
    function valueOf(key):real {return root.editingBar?(SettingsService.macGlassBarProfile[key]??SettingsService[key]):SettingsService[key]}
    function setValue(key,value):void {
        if(root.editingBar)SettingsService.set("macGlassBarProfile",Object.assign({},SettingsService.macGlassBarProfile,{[key]:value}))
        else SettingsService.set(key,value)
    }
    component GlassSlider:SettingSlider {required property string key;locked:root.editingBar?!root.barTarget:!root.windowTarget;reason:Tr.t("Enable glass on this target above");value:root.valueOf(key);onMoved:value=>{const n=Math.round(value);root.setValue(key,n);if(key==="macGlassRefractionRange"&&root.valueOf("macGlassRefraction")>n)root.setValue("macGlassRefraction",n)}}

    SettingRow {label:Tr.t("Apply to bar and modules");ToggleSwitch {checked:SettingsService.surfaceStyle==="tahoe";onToggled:value=>{MacGlassService.saveBefore();if(value)SettingsService.set("macGlassProfileTarget","bar");BarColourService.apply({surfaceStyle:value?"tahoe":"classic"})}}}
    SettingRow {label:Tr.t("Apply to Settings app");ToggleSwitch {checked:!SettingsService.settingsBlur && SettingsService.macGlassSettings && (!SettingsDesignService.modern || SettingsDesignService.style.opaque!==true);onToggled:value=>{SettingsService.set("settingsBlur",false);SettingsService.set("macGlassSettings",value);if(SettingsDesignService.modern)SettingsDesignService.set("opaque",!value)}}}
    SettingRow {label:Tr.t("Apply to app windows");ToggleSwitch {checked:SettingsService.macGlassWindows;onToggled:value=>SettingsService.set("macGlassWindows",value)}}
    SettingRow {label:Tr.t("Apply to Files (Nautilus)");ToggleSwitch {checked:!SettingsService.nautilusBlur && SettingsService.macGlassNautilus;onToggled:value=>{SettingsService.set("nautilusBlur",false);SettingsService.set("macGlassNautilus",value)}}}
    SettingRow {label:Tr.t("Apply to file open / save dialogs");reading:Tr.t("Uses the window glass controls below; text and controls stay fully visible");ToggleSwitch {checked:SettingsService.macGlassFileDialogs;onToggled:value=>SettingsService.set("macGlassFileDialogs",value)}}
    SettingRow {label:Tr.t("Apply to terminal");ToggleSwitch {checked:SettingsService.terminalGround==="tahoe";onToggled:value=>MacGlassService.terminal(value)}}
    SettingRow {label:Tr.t("Configure glass for");SegmentedControl {options:[{id:"bar",label:Tr.t("Bar / modules")},{id:"windows",label:Tr.t("Settings / apps / terminal")}];current:SettingsService.macGlassProfileTarget;onSelected:id=>SettingsService.set("macGlassProfileTarget",id)}}
    GlassSlider {key:"macGlassRefraction";label:Tr.t("Refraction");from:0;to:root.valueOf("macGlassRefractionRange");unit:"%"}
    GlassSlider {key:"macGlassRefractionRange";locked:false;label:Tr.t("Maximum refraction on slider");from:100;to:600;unit:"%"}
    SettingRow {visible:!root.editingBar;label:Tr.t("Window refraction area");reading:Tr.t("Full window adds a centre lens. Bar and module contours use edge reach and falloff.");SegmentedControl {options:[{id:"edges",label:Tr.t("Edges")},{id:"full",label:Tr.t("Full window")}];current:SettingsService.macGlassRefractionMode;onSelected:id=>SettingsService.set("macGlassRefractionMode",id)}}
    GlassSlider {key:"macGlassEdgeWidth";locked:(root.editingBar?!root.barTarget:!root.windowTarget)||root.valueOf("macGlassRefraction")===0;reason:Tr.t("Enable glass and raise Refraction above zero");label:root.editingBar?Tr.t("Edge reach (relative to bar)"):Tr.t("Edge reach towards centre");from:1;to:120;unit:root.editingBar?"%":" px"}
    GlassSlider {key:"macGlassSpread";locked:(root.editingBar?!root.barTarget:!root.windowTarget)||root.valueOf("macGlassRefraction")===0;reason:Tr.t("Enable glass and raise Refraction above zero");label:Tr.t("Edge-to-centre falloff");from:0;to:100;unit:"%"}
    GlassSlider {visible:!root.editingBar&&SettingsService.macGlassRefractionMode==="full";locked:SettingsService.macGlassRefraction===0;reason:Tr.t("Raise Refraction above zero");key:"macGlassCentreStrength";label:Tr.t("Centre lens strength");from:0;to:100;unit:"%"}
    GlassSlider {visible:!root.editingBar;locked:(root.editingBar?!root.barTarget:!root.windowTarget)||root.valueOf("macGlassRefraction")===0;reason:Tr.t("Enable glass and raise Refraction above zero");key:"macGlassFlow";label:Tr.t("Window refraction direction");from:0;to:100;unit:"%"}
    GlassSlider {key:"macGlassBlur";label:Tr.t("Blur");from:0;to:22;unit:" px"}
    GlassSlider {key:"macGlassTint";label:Tr.t("Tint / opacity");from:0;to:100;unit:"%"}
    GlassSlider {key:"macGlassShine";label:Tr.t("Edge light");from:0;to:100;unit:"%"}

    SettingRow {label:Tr.t("Save current glass preset");reading:Tr.t("Includes all targets and their independent values. Manage saved presets under Presets → MacShell glass.");PillButton {text:Tr.t("Save preset");onClicked:MacGlassPresetService.save("Glass "+Qt.formatDateTime(new Date(),"dd MMM HH:mm"))}}
    SettingRow {label:Tr.t("Restore appearance from before MacShell glass");PillButton {text:Tr.t("Restore");onClicked:MacGlassService.restore()}}
}
