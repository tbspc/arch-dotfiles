import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../services"
import "../theme"
SettingsSection {
    id:root
    property string tab:"style"
    readonly property var styles:[{id:"slide-fade",name:Tr.t("Smooth glide")},{id:"slide",name:Tr.t("Slide")},{id:"fade",name:Tr.t("Fade")},{id:"spring",name:Tr.t("Soft spring")},{id:"lift",name:Tr.t("Lift & fade")},{id:"none",name:Tr.t("Instant")}]
    SettingGroup {
        title:Tr.t("Auto-hide bar / Island")
        SettingRow {label:Tr.t("Auto-hide");reading:Tr.t("Reveal at the top edge. Calendar and media use Click until Auto-hide is off.")
            ToggleSwitch {checked:SettingsService.barAutoHide;onToggled:value=>SettingsService.set("barAutoHide",value)}
        }
        SettingRow {label:Tr.t("Smart Auto-hide");reading:Tr.t("Keep the bar visible until a window overlaps it.");locked:!SettingsService.barAutoHide;reason:Tr.t("Enable Auto-hide first")
            ToggleSwitch {checked:SettingsService.barAutoHideSmart;onToggled:value=>SettingsService.set("barAutoHideSmart",value)}
        }
    }
    SettingGroup {
        visible:root.tab==="style";title:Tr.t("Animation style")
        SettingBlock {
            GridLayout {Layout.fillWidth:true;columns:width>=650?4:3;rowSpacing:10;columnSpacing:10
                Repeater {model:root.styles
                    PreviewTile {
                        id:tile
                        required property var modelData
                        stageHeight:94;caption:modelData.name;selected:SettingsService.autoHideAnimation===modelData.id
                        onPicked:SettingsService.set("autoHideAnimation",modelData.id)
                        Rectangle {
                            id:previewStage
                            anchors.fill:parent;anchors.margins:5;radius:8;color:Theme.surfaceHoverIn(QsWindow.window);clip:true
                            property bool hide:false
                            AutoHideMotion {id:motion;hidden:previewStage.hide;style:tile.modelData.id;showDuration:SettingsService.autoHideShowDuration;hideDuration:SettingsService.autoHideHideDuration;distance:35}
                            Rectangle {width:parent.width*.68;height:22;radius:11;anchors.horizontalCenter:parent.horizontalCenter;y:16+motion.offset;opacity:motion.alpha;scale:motion.zoom;color:Theme.textIn(QsWindow.window)
                                Text {anchors.centerIn:parent;text:"9:41";color:Theme.surfaceIn(QsWindow.window);font.family:Theme.fontFamily;font.pixelSize:11}
                            }
                            Timer {interval:Math.max(1100,SettingsService.autoHideShowDuration+SettingsService.autoHideHideDuration+400);running:root.visible&&root.tab==="style";repeat:true;onTriggered:previewStage.hide=!previewStage.hide}
                        }
                    }
                }
            }
        }
    }
    SettingGroup {
        visible:root.tab==="timing";title:Tr.t("Timing & movement")
        SettingSlider {label:Tr.t("Reveal duration");from:100;to:900;unit:" ms";value:SettingsService.autoHideShowDuration;onMoved:value=>SettingsService.set("autoHideShowDuration",Math.round(value))}
        SettingSlider {label:Tr.t("Hide duration");from:100;to:900;unit:" ms";value:SettingsService.autoHideHideDuration;onMoved:value=>SettingsService.set("autoHideHideDuration",Math.round(value))}
        SettingSlider {label:Tr.t("Wait before hiding");from:100;to:2500;unit:" ms";value:SettingsService.autoHideDelay;onMoved:value=>SettingsService.set("autoHideDelay",Math.round(value))}
        SettingSlider {label:Tr.t("Extra travel");from:0;to:80;unit:" px";value:SettingsService.autoHideTravel;onMoved:value=>SettingsService.set("autoHideTravel",Math.round(value))}
        SettingSlider {label:Tr.t("Top-edge target height");from:2;to:12;unit:" px";value:SettingsService.autoHideEdge;onMoved:value=>SettingsService.set("autoHideEdge",Math.round(value))}
    }
}
