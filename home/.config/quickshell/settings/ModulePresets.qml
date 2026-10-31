import QtQuick
import Quickshell
import QtQuick.Layouts
import "../theme"
import "../services"
import "../components"
Flickable {
    id:root
    required property var editor
    property string name:""
    property string deleting:""
    clip:true
    contentHeight:body.implicitHeight
    onEditorChanged:ModulePresetService.seed()
    ColumnLayout{
        id:body;width:parent.width;spacing:12
        Text{Layout.fillWidth:true;wrapMode:Text.WordWrap;text:Tr.t("Each module has its own original configuration and two starting designs. Presets keep its appearance and internal element layout.");font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeSmall;color:Theme.mutedIn(QsWindow.window)}
        SettingField{label:Tr.t("Preset name");placeholder:Tr.t("My module");value:root.name;onEdited:value=>root.name=value}
        PillButton{text:Tr.t("Save current module");active:true;onClicked:{ModulePresetService.save(root.editor.selected,root.name);root.name=""}}
        Repeater{
            model:ModulePresetService.list(root.editor.selected)
            Rectangle{
                id:card
                required property var modelData
                Layout.fillWidth:true;implicitHeight:128;radius:Theme.radiusMedium;color:Theme.colourIn(QsWindow.window,"fieldBackground",Theme.islandSurface);border.width:1;border.color:Theme.colourIn(QsWindow.window,"borderColor",Theme.border)
                ColumnLayout{anchors.fill:parent;anchors.margins:12;spacing:8
                    Text{text:card.modelData.name;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeMedium;font.weight:Font.DemiBold;color:Theme.textIn(QsWindow.window)}
                    Text{Layout.fillWidth:true;wrapMode:Text.WordWrap;text:card.modelData.description;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeSmall;color:Theme.mutedIn(QsWindow.window)}
                    RowLayout{Layout.fillWidth:true
                        PillButton{text:Tr.t("Apply");onClicked:{root.editor.selectedElement=null;root.editor.selectedChip="";ModulePresetService.apply(root.editor.selected,card.modelData.values)}}
                        Item{Layout.fillWidth:true}
                        PillButton{visible:card.modelData.editable;text:Tr.t("Update");onClicked:ModulePresetService.update(root.editor.selected,card.modelData.id)}
                        PillButton{visible:card.modelData.editable;text:root.deleting===card.modelData.id?Tr.t("Confirm delete"):Tr.t("Delete");onClicked:{if(root.deleting===card.modelData.id){ModulePresetService.remove(root.editor.selected,card.modelData.id);root.deleting=""}else root.deleting=card.modelData.id}}
                    }
                }
            }
        }
    }
}
