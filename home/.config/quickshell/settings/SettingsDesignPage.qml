import QtQuick
import Quickshell
import QtQuick.Layouts
import "../services"
import "../theme"
import "../components"
SettingsSection {
    id:root
    property string tab:""
    property string name:""
    property string deleting:""
    SettingGroup {
        title: Tr.t("Settings colours")
        SettingRow {
            label: Tr.t("Use wallpaper theme accent")
            reading: Tr.t("Off uses your chosen accent. The Arch logo always follows wallpaper colours.")
            ToggleSwitch {
                checked: SettingsDesignService.style.useThemeAccent !== false
                onToggled: checked => SettingsDesignService.set("useThemeAccent",checked)
            }
        }
    }
    SettingGroup{title:Tr.t("Your settings layout");note:Tr.t("Your original design is saved below. Designs change navigation and spacing; all settings remain available.")
        SettingField{label:Tr.t("Design name");placeholder:Tr.t("My settings design");value:root.name;onEdited:value=>root.name=value}
        SettingRow{label:Tr.t("Save the active design");PillButton{text:Tr.t("Save current");active:true;onClicked:{SettingsDesignService.save(root.name);root.name=""}}}
    }
    component DesignCard:Rectangle {
        id:card
        required property var design
        property bool editable:false
        Layout.fillWidth:true;implicitHeight:210;radius:Theme.radiusMedium;color:Theme.colourIn(QsWindow.window,"fieldBackground",Theme.surface);border.width:1;border.color:Theme.colourIn(QsWindow.window,"borderColor",Theme.border)
        ColumnLayout{anchors.fill:parent;anchors.margins:12;spacing:8
            Rectangle{Layout.fillWidth:true;Layout.preferredHeight:104;radius:8;color:card.design.values.background||Theme.island;border.width:1;border.color:Theme.colourIn(QsWindow.window,"borderColor",Theme.border)
                readonly property bool topNavigation:card.design.values.navigation==="top"
                Rectangle{width:parent.topNavigation?parent.width-12:card.design.values.navigation==="rail"?24:70;height:parent.topNavigation?24:parent.height-12;x:6;y:6;radius:5;color:Qt.alpha(Theme.accentIn(QsWindow.window),.14)
                    Repeater{model:parent.parent.topNavigation?4:5;Rectangle{required property int index;x:parent.parent.topNavigation?8+index*38:6;y:parent.parent.topNavigation?9:8+index*15;width:parent.parent.topNavigation?28:parent.width-12;height:4;radius:2;color:Qt.alpha(Theme.accentIn(QsWindow.window),index===1?.9:.35)}}
                }
                Column{ x:parent.topNavigation?10:card.design.values.navigation==="rail"?38:84;y:parent.topNavigation?38:12;width:parent.width-x-10;spacing:6
                    Repeater{model:3;Rectangle{width:parent.width;height:17;radius:Math.min(6,card.design.values.cardRadius/3);color:card.design.values.outline?"transparent":card.design.values.cardBackground||Theme.colourIn(QsWindow.window,"fieldBackground",Theme.islandSurface);border.width:1;border.color:card.design.values.outline?Qt.alpha(Theme.accentIn(QsWindow.window),.4):Theme.colourIn(QsWindow.window,"borderColor",Theme.border)}}
                }
            }
            Text{text:card.design.name;color:Theme.textIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeMedium;font.weight:Font.DemiBold}
            Text{Layout.fillWidth:true;text:card.design.description||Tr.t("Your saved settings design");elide:Text.ElideRight;color:Theme.mutedIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeSmall}
            RowLayout{Layout.fillWidth:true
                PillButton{text:Tr.t("Apply");onClicked:SettingsDesignService.apply(card.design.values)}
                Item{Layout.fillWidth:true}
                PillButton{visible:card.editable;text:Tr.t("Update");onClicked:SettingsDesignService.update(card.design.id)}
                PillButton{visible:card.editable;text:root.deleting===card.design.id?Tr.t("Confirm delete"):Tr.t("Delete");onClicked:{if(root.deleting===card.design.id){SettingsDesignService.remove(card.design.id);root.deleting=""}else root.deleting=card.design.id}}
            }
        }
    }
    SettingGroup{title:Tr.t("Saved designs");bare:true
        GridLayout{Layout.fillWidth:true;columns:width>=680?2:1;columnSpacing:12;rowSpacing:12;Repeater{model:SettingsDesignService.saved;DesignCard{required property var modelData;design:modelData;editable:true}}}
    }
    SettingGroup{title:Tr.t("Designs to try");bare:true
        GridLayout{Layout.fillWidth:true;columns:width>=680?2:1;columnSpacing:12;rowSpacing:12;Repeater{model:SettingsDesignService.designs;DesignCard{required property var modelData;design:modelData}}}
    }
}
