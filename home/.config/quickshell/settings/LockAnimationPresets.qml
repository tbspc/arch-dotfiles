import QtQuick
import Quickshell
import QtQuick.Layouts
import "../theme"
import "../services"
import "../components"
SettingsSection {
    id:root
    property string name:""
    property string deleting:""
    SettingGroup{title:Tr.t("Animation presets");note:Tr.t("Your active animation is saved first. Presets change motion only; your lock-screen layout stays as it is.")
        SettingField{label:Tr.t("Preset name");placeholder:Tr.t("My animation");value:root.name;onEdited:value=>root.name=value}
        SettingRow{label:Tr.t("Save the active animation");Row{spacing:8
            PillButton{visible:LockAnimationPresetService.previous!==null;text:Tr.t("Undo apply");onClicked:LockAnimationPresetService.undo()}
            PillButton{text:Tr.t("Save current");active:true;onClicked:{LockAnimationPresetService.save(root.name);root.name=""}}
        }}
    }
    component MotionCard:Rectangle{
        id:card
        required property var preset
        Layout.fillWidth:true;implicitHeight:220;radius:Theme.radiusMedium;color:Theme.colourIn(QsWindow.window,"fieldBackground",Theme.surface);border.width:1;border.color:LockAnimationPresetService.matches(preset.values)?Theme.accentIn(QsWindow.window):Theme.colourIn(QsWindow.window,"borderColor",Theme.border)
        ColumnLayout{anchors.fill:parent;anchors.margins:12;spacing:8
            Rectangle{
                id:preview
                Layout.fillWidth:true;Layout.preferredHeight:82;radius:9;color:Theme.colourIn(QsWindow.window,"fieldBackground",Theme.islandSurface);clip:true
                property real progress:.55
                readonly property bool slide:card.preset.values.lockAnimation==="bar-slide"
                Rectangle{width:parent.width;height:parent.height;color:Qt.alpha(Theme.accentIn(QsWindow.window),.25);y:preview.slide?-height+preview.progress*(height+20):card.preset.values.lockAnimation==="soft-slide"?(1-preview.progress)*14:0;opacity:preview.slide||card.preset.values.lockAnimation==="none"?1:preview.progress
                    Text{anchors.centerIn:parent;text:"12:38";font.family:Theme.fontIn(QsWindow.window);font.pixelSize:26;font.weight:Font.Bold;color:Theme.textIn(QsWindow.window)}
                }
                Rectangle{visible:preview.slide;anchors.horizontalCenter:parent.horizontalCenter;width:36;height:10;radius:5;y:-12+preview.progress*(preview.height+22);color:Theme.colourIn(QsWindow.window,"cardBackground",Theme.islandGround)}
                HoverHandler{id:motionHover}
                NumberAnimation{id:demo;target:preview;property:"progress";from:0;to:1;duration:card.preset.values.lockAnimation==="none"?1:card.preset.values.lockAnimationDuration*100/card.preset.values.lockAnimationSpeed;running:motionHover.hovered;loops:Animation.Infinite;easing.type:card.preset.values.lockAnimationMovement==="quint"?Easing.OutQuint:card.preset.values.lockAnimationMovement==="glide"?Easing.OutCubic:card.preset.values.lockAnimationMovement==="bounce"?Easing.OutBounce:card.preset.values.lockAnimationMovement==="spring"?Easing.OutBack:card.preset.values.lockAnimationMovement==="linear"?Easing.Linear:Easing.InOutCubic}
            }
            Text{text:card.preset.name;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeMedium;font.weight:Font.DemiBold;color:Theme.textIn(QsWindow.window)}
            Text{Layout.fillWidth:true;text:card.preset.description||Tr.t("Your saved motion settings");elide:Text.ElideRight;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeSmall;color:Theme.mutedIn(QsWindow.window)}
            RowLayout{Layout.fillWidth:true
                PillButton{text:Tr.t("Apply");onClicked:LockAnimationPresetService.apply(card.preset.values)}
                Item{Layout.fillWidth:true}
                PillButton{text:Tr.t("Update");onClicked:LockAnimationPresetService.update(card.preset.id)}
                PillButton{text:root.deleting===card.preset.id?Tr.t("Confirm delete"):Tr.t("Delete");onClicked:{if(root.deleting===card.preset.id){LockAnimationPresetService.remove(card.preset.id);root.deleting=""}else root.deleting=card.preset.id}}
            }
        }
    }
    SettingGroup{title:Tr.t("Saved animations");bare:true
        GridLayout{Layout.fillWidth:true;columns:width>=680?2:1;columnSpacing:12;rowSpacing:12;Repeater{model:LockAnimationPresetService.saved;MotionCard{required property var modelData;preset:modelData}}}
    }
    SettingRow{label:Tr.t("Built-in animations");PillButton{text:Tr.t("Restore presets");onClicked:LockAnimationPresetService.restore()}}
    SettingGroup{title:Tr.t("Animations to try · hover to preview");bare:true
        GridLayout{Layout.fillWidth:true;columns:width>=680?2:1;columnSpacing:12;rowSpacing:12;Repeater{model:LockAnimationPresetService.designs;MotionCard{required property var modelData;preset:modelData}}}
    }
}
