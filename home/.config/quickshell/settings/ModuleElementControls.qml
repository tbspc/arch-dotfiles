import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls as Controls
import "../components"
import "../services"
import "../theme"
Flickable {
    id:root
    required property var editor
    clip:true
    contentHeight:body.implicitHeight
    ColumnLayout{
        id:body;width:parent.width;spacing:8
        Text{Layout.fillWidth:true;wrapMode:Text.WordWrap;text:root.editor.selectedChip?IslandChipService.names[root.editor.selectedChip]:root.editor.selectedElement?ModuleService.designLabel(root.editor.selectedElement):Tr.t("Select an element in the preview, or choose one below.");font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeMedium;color:Theme.textIn(QsWindow.window)}
        RowLayout{
            visible:root.editor.selected==="bar"
            PillButton{text:Tr.t("Clock");onClicked:root.editor.selectNamed("design:ClockModule:6")}
            PillButton{text:Tr.t("Media artwork");onClicked:root.editor.selectNamed("design:media-artwork")}
            PillButton{text:Tr.t("Playback indicator");onClicked:root.editor.selectNamed("design:media-spectrum")}
        }
        ThemedComboBox{
            Layout.fillWidth:true;model:root.editor.targetElements.map(item=>typeof item.chipId==="string"?IslandChipService.names[item.chipId]+" chip":ModuleService.designLabel(item))
            currentIndex:root.editor.targetElements.indexOf(root.editor.selectedElement)
            onActivated:root.editor.choose(root.editor.targetElements[currentIndex])
            onPressedChanged:if(pressed)root.editor.refreshElements()
        }
        ColumnLayout{
            Layout.fillWidth:true;visible:root.editor.selectedChip!==""
            SegmentedControl{visible:root.editor.selectedChip==="media";options:[{id:"",label:Tr.t("Chip")},{id:"previous",label:Tr.t("Previous")},{id:"play",label:Tr.t("Play/pause")},{id:"next",label:Tr.t("Next")}];current:root.editor.selectedControl;onSelected:id=>root.editor.selectedControl=id}
            SegmentedControl{visible:!root.editor.selectedControl;options:[{id:"left",label:Tr.t("Left")},{id:"right",label:Tr.t("Right")}];current:root.editor.chipStyle.side??"left";onSelected:id=>root.editor.setChip("side",id)}
            SettingSlider{label:Tr.t("Horizontal position");from:-500;to:500;unit:" px";value:root.editor.selectedControl?root.editor.controlStyle.x??0:root.editor.chipStyle.offsetX??0;onMoved:value=>root.editor.setChip(root.editor.selectedControl?"x":"offsetX",Math.round(value))}
            SettingSlider{label:Tr.t("Vertical position");from:-120;to:120;unit:" px";value:root.editor.selectedControl?root.editor.controlStyle.y??0:root.editor.chipStyle.offsetY??0;onMoved:value=>root.editor.setChip(root.editor.selectedControl?"y":"offsetY",Math.round(value))}
            SettingSlider{visible:!root.editor.selectedControl;label:Tr.t("Width");from:18;to:520;unit:" px";value:root.editor.chipStyle.width??36;onMoved:value=>root.editor.setChip("width",Math.round(value))}
            SettingSlider{visible:!root.editor.selectedControl;label:Tr.t("Height");from:18;to:80;unit:" px";value:root.editor.chipStyle.height??36;onMoved:value=>root.editor.setChip("height",Math.round(value))}
            SettingSlider{label:Tr.t("Icon size");from:50;to:180;unit:"%";value:root.editor.selectedControl?root.editor.controlStyle.scale??100:root.editor.chipStyle.iconScale??100;onMoved:value=>root.editor.setChip(root.editor.selectedControl?"scale":"iconScale",Math.round(value))}
            SegmentedControl{visible:!root.editor.selectedControl;options:[{id:"circle",label:Tr.t("Round")},{id:"rounded",label:Tr.t("Rounded")},{id:"pill",label:Tr.t("Pill")}];current:root.editor.chipStyle.style??"circle";onSelected:id=>root.editor.setChip("style",id)}
            SegmentedControl{visible:!root.editor.selectedControl;options:[{id:"solid",label:Tr.t("Solid")},{id:"theme",label:Tr.t("Theme")},{id:"glass",label:Tr.t("Glass")},{id:"outline",label:Tr.t("Outline")}];current:root.editor.chipStyle.surface??"solid";onSelected:id=>root.editor.setChip("surface",id)}
            SegmentedControl{visible:root.editor.selectedChip==="media" && !root.editor.selectedControl;options:[{id:"artwork",label:Tr.t("Artwork")},{id:"controls",label:Tr.t("Controls")},{id:"title",label:Tr.t("Title")}];current:root.editor.chipStyle.display??"artwork";onSelected:id=>root.editor.setChip("display",id)}
            SettingRow{visible:root.editor.selectedChip==="media" && !root.editor.selectedControl;label:Tr.t("Hide when paused");ToggleSwitch{checked:root.editor.chipStyle.autoHide??true;onToggled:checked=>root.editor.setChip("autoHide",checked)}}
            PillButton{visible:!root.editor.selectedControl;text:Tr.t("Remove chip");onClicked:{root.editor.setChip("enabled",false);root.editor.selectedElement=null;root.editor.selectedChip=""}}
        }
        ColumnLayout{
            Layout.fillWidth:true;visible:root.editor.selectedElement!==null && !root.editor.selectedChip
            SettingSlider{label:Tr.t("Horizontal position");from:-600;to:600;unit:" px";value:root.editor.elementStyle.x??0;onMoved:value=>root.editor.setElement("x",Math.round(value))}
            SettingSlider{label:Tr.t("Vertical position");from:-400;to:400;unit:" px";value:root.editor.elementStyle.y??0;onMoved:value=>root.editor.setElement("y",Math.round(value))}
            SettingSlider{label:Tr.t("Width scale");from:20;to:250;unit:"%";value:root.editor.elementStyle.widthScale??100;onMoved:value=>root.editor.setElement("widthScale",Math.round(value))}
            SettingSlider{label:Tr.t("Height scale");from:20;to:250;unit:"%";value:root.editor.elementStyle.heightScale??100;onMoved:value=>root.editor.setElement("heightScale",Math.round(value))}
            SettingSlider{label:Tr.t("Opacity");from:0;to:100;unit:"%";value:root.editor.elementStyle.opacity??100;onMoved:value=>root.editor.setElement("opacity",Math.round(value))}
            SettingField{visible:root.editor.selectedElement && "color" in root.editor.selectedElement;label:Tr.t("Colour");placeholder:Tr.t("Blank follows theme; #RRGGBB or #AARRGGBB");value:root.editor.elementStyle.color??"";onEdited:value=>{if(!value || /^#[0-9a-fA-F]{6}$|^#[0-9a-fA-F]{8}$/.test(value))root.editor.setElement("color",value||undefined)}}
            SettingSlider{visible:root.editor.selectedElement && "font" in root.editor.selectedElement;label:Tr.t("Font size");from:6;to:100;unit:" px";value:root.editor.elementStyle.fontSize??root.editor.selectedElement?.font?.pixelSize??14;onMoved:value=>root.editor.setElement("fontSize",Math.round(value))}
            SettingField{visible:root.editor.selectedElement && "font" in root.editor.selectedElement;label:Tr.t("Font family");value:root.editor.elementStyle.fontFamily??"";placeholder:Tr.t("Blank follows theme");onEdited:value=>root.editor.setElement("fontFamily",value.trim())}
            PillButton{text:Tr.t("Reset element");onClicked:root.editor.resetElement()}
        }
    }
}
