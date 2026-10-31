import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"
import "../components"
SettingsSection {
    id:root
    property string tab:"layout"
    readonly property var design:LauncherPresetService.style
    LauncherPresetPreview{Layout.fillWidth:true;large:true;values:LauncherPresetService.capture()}
    SettingRow{label:Tr.t("Live preview");PillButton{text:Tr.t("Open launcher");onClicked:ModuleService.togglePanel("launcher")}}
    SettingGroup{visible:root.tab==="layout";title:Tr.t("Emoji selector")
        SettingRow{label:Tr.t("Use launcher design for emoji");reading:SettingsService.emojiFollowsLauncher?Tr.t("Shared layout"):Tr.t("Original independent layout");ToggleSwitch{checked:SettingsService.emojiFollowsLauncher;onToggled:checked=>SettingsService.set("emojiFollowsLauncher",checked)}}
    }
    SettingGroup{
        visible:root.tab==="layout";title:Tr.t("Panel and spacing")
        Repeater{
            model:[{key:"width",label:"Panel width",min:320,max:1100},{key:"height",label:"Fixed panel height",min:220,max:900},{key:"padding",label:"Panel padding",min:4,max:48},{key:"cornerRadius",label:"Panel rounding",min:0,max:48},{key:"fieldHeight",label:"Search field height",min:26,max:80},{key:"rowHeight",label:"Minimum row height",min:28,max:100},{key:"rowSpacing",label:"Gap between rows",min:0,max:18},{key:"rowPadding",label:"Row side padding",min:4,max:40},{key:"rowVerticalPadding",label:"Row vertical padding",min:0,max:20},{key:"contentGap",label:"Icon-to-text gap",min:4,max:32},{key:"gap",label:"Section spacing",min:4,max:30},{key:"textGap",label:"Title-to-description gap",min:0,max:10},{key:"emojiCell",label:"Emoji cell size",min:32,max:90}]
            SettingSlider{required property var modelData;label:Tr.t(modelData.label);from:modelData.min;to:modelData.max;unit:" px";value:root.design[modelData.key];onMoved:value=>LauncherPresetService.setStyle(modelData.key,Math.round(value))}
        }
    }
    SettingGroup{
        visible:root.tab==="appearance";title:Tr.t("Text and icons")
        SettingRow{label:Tr.t("Background");SegmentedControl{options:[{id:"theme",label:Tr.t("Theme")},{id:"grey",label:Tr.t("Dark grey")},{id:"black",label:Tr.t("Black")}];current:root.design.surfaceTone;onSelected:id=>LauncherPresetService.setStyle("surfaceTone",id)}}
        SettingField{label:Tr.t("Font family");placeholder:Tr.t("Blank follows the shell font");value:root.design.fontFamily;onEdited:value=>LauncherPresetService.setStyle("fontFamily",value.trim())}
        SettingField{label:Tr.t("Search placeholder");value:root.design.placeholder;onEdited:value=>LauncherPresetService.setStyle("placeholder",value)}
        Repeater{
            model:[{key:"titleSize",label:"App name size",min:10,max:30},{key:"subtitleSize",label:"Description size",min:8,max:22},{key:"searchSize",label:"Search text size",min:12,max:32},{key:"searchIconSize",label:"Search icon size",min:12,max:36},{key:"iconSize",label:"App icon size",min:18,max:64},{key:"iconPadding",label:"Icon inset",min:0,max:12},{key:"iconRadius",label:"Icon rounding",min:0,max:28},{key:"rowRadius",label:"Selection rounding",min:0,max:40},{key:"emojiSize",label:"Emoji size",min:18,max:56}]
            SettingSlider{required property var modelData;label:Tr.t(modelData.label);from:modelData.min;to:modelData.max;unit:" px";value:root.design[modelData.key];onMoved:value=>LauncherPresetService.setStyle(modelData.key,Math.round(value))}
        }
        SettingRow{label:Tr.t("App name weight");SegmentedControl{options:[{id:"400",label:Tr.t("Regular")},{id:"500",label:Tr.t("Medium")},{id:"600",label:Tr.t("Bold")}];current:String(root.design.titleWeight);onSelected:id=>LauncherPresetService.setStyle("titleWeight",Number(id))}}
        Repeater{
            model:[{key:"showIcons",label:"App icons"},{key:"iconTiles",label:"Icon backgrounds"},{key:"showSubtitles",label:"Descriptions"},{key:"showPinned",label:"Pinned-app marks"},{key:"showSearchIcon",label:"Search icon"},{key:"showDivider",label:"Search divider"}]
            SettingRow{required property var modelData;label:Tr.t(modelData.label);ToggleSwitch{checked:root.design[modelData.key];onToggled:checked=>LauncherPresetService.setStyle(modelData.key,checked)}}
        }
    }
    SettingGroup{
        visible:root.tab==="appearance";title:Tr.t("Selection")
        SettingRow{label:Tr.t("Highlight");SegmentedControl{options:[{id:"soft",label:Tr.t("Soft")},{id:"accent",label:Tr.t("Accent")},{id:"outline",label:Tr.t("Outline")},{id:"none",label:Tr.t("None")}];current:root.design.highlightStyle;onSelected:id=>LauncherPresetService.setStyle("highlightStyle",id)}}
        SettingSlider{label:Tr.t("Highlight opacity");from:0;to:60;unit:"%";value:root.design.highlightOpacity;onMoved:value=>LauncherPresetService.setStyle("highlightOpacity",Math.round(value))}
        SettingSlider{label:Tr.t("Border opacity");from:0;to:100;unit:"%";value:root.design.borderOpacity;onMoved:value=>LauncherPresetService.setStyle("borderOpacity",Math.round(value))}
        SettingRow{label:Tr.t("Accent marker");SegmentedControl{options:[{id:"line",label:Tr.t("Line")},{id:"dot",label:Tr.t("Dot")},{id:"none",label:Tr.t("None")}];current:root.design.indicatorStyle;onSelected:id=>LauncherPresetService.setStyle("indicatorStyle",id)}}
        SettingSlider{label:Tr.t("Marker width");from:1;to:8;unit:" px";value:root.design.indicatorWidth;onMoved:value=>LauncherPresetService.setStyle("indicatorWidth",Math.round(value))}
        SettingSlider{label:Tr.t("Marker height");from:15;to:90;unit:"%";value:root.design.indicatorHeight;onMoved:value=>LauncherPresetService.setStyle("indicatorHeight",Math.round(value))}
    }
    SettingGroup{
        visible:root.tab==="motion";title:Tr.t("Selection movement")
        SettingRow{label:Tr.t("Animation");SegmentedControl{options:[{id:"slide",label:Tr.t("Slide")},{id:"fade",label:Tr.t("Fade")},{id:"snap",label:Tr.t("Instant")}];current:root.design.selectionMotion;onSelected:id=>LauncherPresetService.setStyle("selectionMotion",id)}}
        SettingSlider{label:Tr.t("Selection speed");from:0;to:450;unit:" ms";value:root.design.motionDuration;onMoved:value=>LauncherPresetService.setStyle("motionDuration",Math.round(value))}
        SettingRow{label:Tr.t("Select on pointer movement");ToggleSwitch{checked:root.design.hoverSelect;onToggled:checked=>LauncherPresetService.setStyle("hoverSelect",checked)}}
        SettingRow{label:Tr.t("Wrap arrow navigation");ToggleSwitch{checked:root.design.wrapNavigation;onToggled:checked=>LauncherPresetService.setStyle("wrapNavigation",checked)}}
    }
}
