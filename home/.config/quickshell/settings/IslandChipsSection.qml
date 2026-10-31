import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../services"
import "../components"
import "../bar/widgets"
SettingsSection {
    id:root
    property string selected:"clock"
    property string part:"position"
    readonly property var config:IslandChipService.get(selected)
    SettingGroup {
        title:Tr.t("Individual chips")
        note:Tr.t("Choose a preview, then change its position, size or appearance.")
        SettingRow {label:Tr.t("Separate chips");ToggleSwitch {checked:SettingsService.islandChipsEnabled;onToggled:checked=>{SettingsService.set("islandChipsEnabled",checked);if(checked&&["bezel","island"].includes(SettingsService.barStyle))SettingsService.set("barStyle","grouped")}}}
        SettingSlider {label:Tr.t("Gap between chips");from:2;to:48;unit:" px";value:SettingsService.islandChipGap;onMoved:value=>SettingsService.set("islandChipGap",Math.round(value))}
        SettingBlock {
            GridLayout {
                Layout.fillWidth:true;columns:width>=650?4:3;columnSpacing:10;rowSpacing:10
                Repeater {model:["clock","workspaces","media","internet","bluetooth","speaker","battery"]
                    Rectangle {
                        id:card
                        required property string modelData
                        readonly property var chip:IslandChipService.get(modelData)
                        Layout.fillWidth:true;Layout.preferredWidth:1;implicitHeight:110;radius:12
                        color:Theme.surfaceIn(QsWindow.window);border.width:1;border.color:root.selected===modelData?Theme.accentIn(QsWindow.window):Theme.borderIn(QsWindow.window)
                        Item {anchors.top:parent.top;anchors.topMargin:10;anchors.horizontalCenter:parent.horizontalCenter;width:parent.width-16;height:62
                            IndividualIslandChip {visible:card.modelData!=="clock";anchors.centerIn:parent;chipId:card.modelData;configuration:card.chip;preview:true;width:implicitWidth;height:implicitHeight;scale:Math.min(1,(parent.width-8)/Math.max(1,width),52/Math.max(1,height))}
                            Rectangle {visible:card.modelData==="clock";anchors.centerIn:parent;width:Math.min(parent.width-8,card.chip.width);height:Math.min(52,card.chip.height);radius:card.chip.style==="rounded"?10:height/2;color:Theme.colourIn(QsWindow.window,"cardBackground",Theme.islandGround);border.color:Theme.colourIn(QsWindow.window,"borderColor",Theme.border);border.width:1
                                Text {anchors.centerIn:parent;text:"9:41";font.family:Theme.fontIn(QsWindow.window);font.pixelSize:SettingsService.islandClockSize;color:Theme.textIn(QsWindow.window)}
                            }
                        }
                        Text {anchors.bottom:parent.bottom;anchors.bottomMargin:12;anchors.horizontalCenter:parent.horizontalCenter;text:Tr.t(IslandChipService.names[card.modelData]);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:12;color:Theme.textIn(QsWindow.window)}
                        TapHandler {onTapped:root.selected=card.modelData}
                    }
                }
            }
        }
    }
    TabStrip {tabs:[{id:"position",label:Tr.t("Position")},{id:"size",label:Tr.t("Size")},{id:"style",label:Tr.t("Style")}];current:root.part;onPicked:id=>root.part=id}
    component ChipSlider:SettingSlider {required property string key;value:root.config[key];onMoved:value=>IslandChipService.set(root.selected,key,Math.round(value))}
    SettingGroup {
        visible:root.part==="position";title:Tr.t(IslandChipService.names[root.selected])+" · "+Tr.t("Position")
        SettingRow {visible:root.selected!=="clock";label:Tr.t("Show chip");ToggleSwitch {checked:root.config.enabled;onToggled:checked=>IslandChipService.set(root.selected,"enabled",checked)}}
        SettingRow {visible:root.selected==="media";label:Tr.t("Hide when nothing is playing");ToggleSwitch {checked:root.config.autoHide;onToggled:checked=>IslandChipService.set("media","autoHide",checked)}}
        SettingRow {visible:root.selected!=="clock";label:Tr.t("Side of clock");SegmentedControl {options:[{id:"left",label:Tr.t("Left")},{id:"right",label:Tr.t("Right")}];current:root.config.side;onSelected:id=>IslandChipService.set(root.selected,"side",id)}}
        ChipSlider {key:"offsetX";label:Tr.t("Horizontal offset");from:-300;to:300;unit:" px"}
        ChipSlider {key:"offsetY";label:Tr.t("Vertical offset");from:-100;to:100;unit:" px"}
        ChipSlider {visible:root.selected!=="clock";key:"order";label:Tr.t("Order on side");from:0;to:10}
    }
    SettingGroup {
        visible:root.part==="size";title:Tr.t("Size")
        ChipSlider {key:"width";label:Tr.t("Width");from:18;to:root.selected==="clock"?400:320;unit:" px"}
        ChipSlider {key:"height";label:Tr.t("Height");from:18;to:80;unit:" px"}
        ChipSlider {visible:root.selected!=="clock";key:"iconScale";label:Tr.t("Contents size");from:50;to:180;unit:"%"}
        SettingSlider {visible:root.selected==="clock";label:Tr.t("Clock size");from:14;to:28;unit:" px";value:SettingsService.islandClockSize;onMoved:value=>SettingsService.set("islandClockSize",Math.round(value))}
    }
    SettingGroup {
        visible:root.part==="style";title:Tr.t("Style")
        SettingRow {label:Tr.t("Shape");SegmentedControl {options:root.selected==="clock"?[{id:"pill",label:Tr.t("Pill")},{id:"rounded",label:Tr.t("Rounded")}]:[{id:"circle",label:Tr.t("Circle")},{id:"pill",label:Tr.t("Pill")},{id:"rounded",label:Tr.t("Rounded")}];current:root.config.style;onSelected:id=>{IslandChipService.set(root.selected,"style",id);if(id==="circle")IslandChipService.set(root.selected,"width",root.config.height)}}}
        SettingRow {label:Tr.t("Surface");SegmentedControl {options:[{id:"solid",label:Tr.t("Dark")},{id:"theme",label:Tr.t("Theme")},{id:"glass",label:Tr.t("Translucent")},{id:"outline",label:Tr.t("Outline")}];current:root.config.surface;onSelected:id=>IslandChipService.set(root.selected,"surface",id)}}
        SettingRow {visible:root.selected==="battery";label:Tr.t("Battery style");SegmentedControl {options:[{id:"old",label:Tr.t("Old")},{id:"new",label:Tr.t("New")},{id:"reference",label:Tr.t("Reference")}];current:SettingsService.islandBatteryIconStyle;onSelected:id=>SettingsService.set("islandBatteryIconStyle",id)}}
        SettingRow {visible:!["clock","workspaces","bluetooth"].includes(root.selected);label:Tr.t("Display")
            ThemedComboBox {
                model:root.selected==="media"?[{id:"artwork",name:Tr.t("Artwork")},{id:"icon",name:Tr.t("Icon")},{id:"title",name:Tr.t("Title")},{id:"controls",name:Tr.t("Controls")}]
                    :root.selected==="battery"?[{id:"ring",name:Tr.t("Ring")},{id:"icon",name:Tr.t("Icon")},{id:"both",name:Tr.t("Icon + %")},{id:"percent",name:Tr.t("Percentage")}]
                    :root.selected==="internet"?[{id:"icon",name:Tr.t("Wi-Fi")},{id:"ring",name:Tr.t("Ring")},{id:"value",name:Tr.t("Network name")}]:[{id:"ring",name:Tr.t("Ring")},{id:"icon",name:Tr.t("Icon")},{id:"value",name:Tr.t("Volume")}]
                textRole:"name";currentIndex:Math.max(0,model.findIndex(e=>e.id===root.config.display));onActivated:IslandChipService.set(root.selected,"display",model[currentIndex].id)
            }
        }
    }
    SettingGroup {
        title:Tr.t("Chip transitions")
        SettingRow {
            label:Tr.t("Move chips beside open modules")
            reading:Tr.t("Chips slide outward with the module and return with it. Turn off to fade them away instead.")
            ToggleSwitch {checked:SettingsService.chipFollowModules;onToggled:checked=>SettingsService.set("chipFollowModules",checked)}
        }
        SettingSlider {label:Tr.t("Hide duration");from:70;to:500;unit:" ms";value:SettingsService.chipHideDuration;onMoved:value=>SettingsService.set("chipHideDuration",Math.round(value))}
        SettingSlider {label:Tr.t("Show duration");from:70;to:600;unit:" ms";value:SettingsService.chipShowDuration;onMoved:value=>SettingsService.set("chipShowDuration",Math.round(value))}
        SettingSlider {label:Tr.t("Delay after module closes");from:0;to:250;unit:" ms";value:SettingsService.chipReturnDelay;onMoved:value=>SettingsService.set("chipReturnDelay",Math.round(value))}
    }

}
