import QtQuick
import Quickshell
import QtQuick.Layouts
import "../theme"
import "../services"
import "../components"
SettingsSection {
    id:root
    property string presetName:""
    property string message:""
    property string deleting:""
    property string query:""
    function matchesSearch(preset:var):bool {
        const text=root.query.trim().toLocaleLowerCase()
        if(!text)return true
        const category=LauncherPresetService.categoryOf(preset.values)
        const subcategory=LauncherPresetService.subcategoryOf(preset.values)
        const categoryName=LauncherPresetService.categories.find(entry=>entry.id===category)?.name||category
        const subcategoryName=LauncherPresetService.subcategories.find(entry=>entry.id===subcategory)?.name||subcategory
        return [preset.name,preset.description||"",category,subcategory,categoryName,subcategoryName]
            .join(" ").toLocaleLowerCase().includes(text)
    }
    property string category:"all"
    property string subcategory:"all"
    readonly property var savedSelection:LauncherPresetService.select(LauncherPresetService.saved,category,subcategory).filter(entry=>root.matchesSearch(entry))
    readonly property var designSelection:LauncherPresetService.select(LauncherPresetService.designs,category,subcategory).filter(entry=>root.matchesSearch(entry))
    SettingGroup{
        title:Tr.t("Save your launcher")
        note:Tr.t("Presets keep the launcher design, result layout and element positions. Other modules and your search history stay as they are.")
        SettingField{label:Tr.t("Preset name");placeholder:Tr.t("My launcher");value:root.presetName;onEdited:value=>root.presetName=value}
        SettingRow{label:root.message||Tr.t("Save the current configuration");Row{spacing:8
            PillButton{visible:LauncherPresetService.previous!==null;text:Tr.t("Undo apply");onClicked:{LauncherPresetService.undo();root.message=Tr.t("Previous launcher restored")}}
            PillButton{text:Tr.t("Save current");active:true;enabled:LauncherPresetService.ready;onClicked:{if(LauncherPresetService.save(root.presetName)){root.presetName="";root.message=Tr.t("Launcher preset saved")}}}
        }}
    }
    SettingRow {label:Tr.t("Launcher preset carousel");PillButton {text:Tr.t("Open carousel");onClicked:ModuleService.requestPanel("launcherpresets")}}
    SettingRow{label:Tr.t("Built-in designs");PillButton{text:Tr.t("Restore built-in presets");onClicked:LauncherPresetService.restore()}}
    SettingGroup{title:Tr.t("Browse presets")
        SettingField{label:Tr.t("Search presets");placeholder:Tr.t("Name, description, category or style…");value:root.query;onEdited:value=>root.query=value}
        SettingRow{label:Tr.t("Layout category");SegmentedControl{options:[{id:"all",label:Tr.t("All")}].concat(LauncherPresetService.categories.map(p=>({id:p.id,label:Tr.t(p.name)})));current:root.category;onSelected:id=>root.category=id}}
        SettingRow{label:Tr.t("Style subcategory");SegmentedControl{options:[{id:"all",label:Tr.t("All")}].concat(LauncherPresetService.subcategories.map(p=>({id:p.id,label:Tr.t(p.name)})));current:root.subcategory;onSelected:id=>root.subcategory=id}}
    }
    component PresetCard:Rectangle{
        id:card
        required property var preset
        readonly property bool applied:LauncherPresetService.matches(preset.values)
        Layout.fillWidth:true;implicitHeight:body.implicitHeight+24
        radius:Theme.radiusMedium;color:Theme.colourIn(QsWindow.window,"fieldBackground",Theme.surface);border.width:1;border.color:applied?Theme.accentIn(QsWindow.window):Theme.colourIn(QsWindow.window,"borderColor",Theme.border)
        ColumnLayout{
            id:body;anchors.left:parent.left;anchors.right:parent.right;anchors.top:parent.top;anchors.margins:12;spacing:10
            LauncherPresetPreview{Layout.fillWidth:true;values:card.preset.values}
            RowLayout{Layout.fillWidth:true
                Text{Layout.fillWidth:true;text:card.preset.name;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeMedium;font.weight:Font.DemiBold;color:Theme.textIn(QsWindow.window);elide:Text.ElideRight}
                Text{visible:card.applied;text:Tr.t("In use");color:Theme.accentIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeSmall}
            }
            Text{Layout.fillWidth:true;text:LauncherPresetService.categoryOf(card.preset.values)+" · "+LauncherPresetService.subcategoryOf(card.preset.values);color:Theme.accentIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeSmall}
            Text{Layout.fillWidth:true;text:card.preset.description||Tr.t("Your saved launcher design");wrapMode:Text.WordWrap;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeSmall;color:Theme.mutedIn(QsWindow.window)}
            RowLayout{Layout.fillWidth:true;spacing:6
                PillButton{text:Tr.t("Apply");active:card.applied;onClicked:{LauncherPresetService.apply(card.preset.values);root.message=Tr.t("Applied")+" · "+card.preset.name}}
                Item{Layout.fillWidth:true}
                PillButton{text:Tr.t("Update");onClicked:{LauncherPresetService.update(card.preset.id);root.message=Tr.t("Updated")+" · "+card.preset.name}}
                PillButton{text:root.deleting===card.preset.id?Tr.t("Confirm delete"):Tr.t("Delete");onClicked:{if(root.deleting===card.preset.id){LauncherPresetService.remove(card.preset.id);root.deleting=""}else root.deleting=card.preset.id}}
            }
        }
    }
    SettingGroup{
        title:Tr.t("Your presets");note:Tr.t("Your original launcher was saved automatically before customization.");bare:true
        GridLayout{Layout.fillWidth:true;columns:width>=680?2:1;columnSpacing:12;rowSpacing:12
            Repeater{model:root.savedSelection;PresetCard{required property var modelData;preset:modelData}}
        }
        Text{visible:root.savedSelection.length===0;text:root.query.trim()?Tr.t("No saved presets match your search."):Tr.t("Save your current launcher to add a preset.");font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeSmall;color:Theme.mutedIn(QsWindow.window)}
    }
    SettingGroup{
        title:Tr.t("Designs to try");bare:true
        Text{visible:root.designSelection.length===0;text:Tr.t("No designs match these filters.");font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeSmall;color:Theme.mutedIn(QsWindow.window)}
        GridLayout{Layout.fillWidth:true;columns:width>=680?2:1;columnSpacing:12;rowSpacing:12
            Repeater{model:root.designSelection;PresetCard{required property var modelData;preset:modelData}}
        }
    }
}
