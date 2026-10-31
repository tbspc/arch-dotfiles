import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../theme"
import "../services"
SettingsSection {
    id:root
    property string tab:""
    property string name:""
    property string deleting:""
    signal panelRequested(string panel)
    SettingGroup {
        title:Tr.t("Save your whole setup")
        note:Tr.t("Save the bar, launcher, modules, editor layouts, lock screen, settings design, wallpaper and palette together. Your current setup is saved automatically. Calendar/media opening behaviour remains global.")
        SettingField {label:Tr.t("Preset name");value:root.name;placeholder:Tr.t("My complete setup");onEdited:value=>root.name=value}
        SettingRow {label:Tr.t("Current configuration");Row {spacing:8
            PillButton {text:Tr.t("Save current");active:true;enabled:SetupPresetService.ready;onClicked:{SetupPresetService.save(root.name);root.name=""}}
            PillButton {visible:SetupPresetService.previous!==null;text:Tr.t("Undo apply");onClicked:SetupPresetService.undo()}
        }}
        SettingRow {label:Tr.t("Browse all preset types");PillButton {text:Tr.t("Open preset browser");onClicked:root.panelRequested("setuppresets")}}
    }
    component SetupCard:Rectangle {
        id:card
        required property var preset
        property bool editable:false
        Layout.fillWidth:true;implicitHeight:body.implicitHeight+28
        radius:18;color:Theme.colourIn(QsWindow.window,"fieldBackground",Theme.surface);border.width:1;border.color:Theme.colourIn(QsWindow.window,"borderColor",Theme.border)
        ColumnLayout {
            id:body;anchors.left:parent.left;anchors.right:parent.right;anchors.top:parent.top;anchors.margins:14;spacing:10
            Rectangle {Layout.fillWidth:true;Layout.preferredHeight:118;radius:12;color:preset.values.settings.settingsDesign?.background||Theme.island
                IslandPresetPreview {anchors.fill:parent;anchors.margins:12;values:card.preset.values.settings}
            }
            Text {Layout.fillWidth:true;text:card.preset.name;color:Theme.textIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:17;font.weight:Font.DemiBold}
            Text {Layout.fillWidth:true;text:card.preset.description;wrapMode:Text.WordWrap;color:Theme.mutedIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:12}
            RowLayout {Layout.fillWidth:true
                PillButton {text:Tr.t("Apply");onClicked:SetupPresetService.apply(card.preset.values)}
                Item {Layout.fillWidth:true}
                PillButton {visible:card.editable;text:Tr.t("Update");onClicked:SetupPresetService.update(card.preset.id)}
                PillButton {visible:card.editable;text:root.deleting===card.preset.id?Tr.t("Confirm delete"):Tr.t("Delete");onClicked:{if(root.deleting===card.preset.id){SetupPresetService.remove(card.preset.id);root.deleting=""}else root.deleting=card.preset.id}}
            }
        }
    }
    SettingGroup {title:Tr.t("Your complete setups");bare:true
        GridLayout {Layout.fillWidth:true;columns:width>=650?2:1;columnSpacing:12;rowSpacing:12
            Repeater {model:SetupPresetService.saved;SetupCard {required property var modelData;preset:modelData;editable:true}}
        }
    }
    SettingGroup {title:Tr.t("Coordinated designs");bare:true
        GridLayout {Layout.fillWidth:true;columns:width>=650?2:1;columnSpacing:12;rowSpacing:12
            Repeater {model:SetupPresetService.designs;SetupCard {required property var modelData;preset:modelData}}
        }
    }
}
