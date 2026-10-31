import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"
import "../components"
import "../bar/island"
SettingGroup {
    readonly property var headerChoices:[{id:"desktop",name:"Desktop"},{id:"none",name:"None"},{id:"media",name:"Media player"},{id:"weather",name:"Weather"},{id:"notifications",name:"Notifications"},{id:"chatgpt",name:"ChatGPT"},{id:"date",name:"Date"},{id:"network",name:"Wi-Fi"},{id:"battery",name:"Battery"},{id:"notes",name:"Notes"},{id:"launcher",name:"App search"},{id:"tasks",name:"Tasks"},{id:"timer",name:"Timer"}]
    id:root
    title:Tr.t("Hover view designs")
    note:Tr.t("Choose the expanded clock view. Status & media mirrors your workspace, signal and battery styling, with music controls.")
    SettingTiles {
        label:Tr.t("Design")
        Repeater {
            model:[{id:"classic",name:"Classic"},{id:"status",name:"Status & media"},{id:"compact",name:"Compact media"},{id:"reference-compact",name:"Reference · Compact"},{id:"reference-media",name:"Reference · Media"}]
            delegate:PreviewTile {
                id:tile
                required property var modelData
                caption:Tr.t(modelData.name);stageHeight:78
                selected:SettingsService.islandHoverDesign===modelData.id
                onPicked:{if(["reference-compact","reference-media"].includes(modelData.id)){if(!ModulePresetService.list("summary").some(p=>p.name==="Before compact hover"))ModulePresetService.save("summary","Before compact hover");ModulePresetService.apply("summary",ModulePresetService.list("summary").find(p=>p.id===(modelData.id==="reference-media"?"reference-media-hover":"reference-compact-hover")).values)}else{SettingsService.set("islandHoverDesign",modelData.id);SettingsService.set("islandHoverLayout",Object.assign({},SettingsService.pristine.islandHoverLayout,{enabled:false}))}}
                Item {
                    anchors.fill:parent;clip:true
                    Rectangle {
                        anchors.centerIn:parent;width:parent.width-16;height:52;radius:12
                        color:Theme.islandGround
                        Loader {
                            anchors.centerIn:parent
                            width:["reference-compact","reference-media"].includes(tile.modelData.id)?720:tile.modelData.id==="compact"?620:760;height:tile.modelData.id==="reference-media"?138:tile.modelData.id==="reference-compact"?76:96
                            scale:(parent.width-8)/width
                            sourceComponent:tile.modelData.id==="classic"?classic:banner
                        }
                    }
                }
                Component {id:banner;StatusIslandSummary {compact:tile.modelData.id==="compact";preview:true;designOverride:tile.modelData.id;layoutOverride:["reference-compact","reference-media"].includes(tile.modelData.id)?ModulePresetService.list("summary").find(p=>p.id===(tile.modelData.id==="reference-media"?"reference-media-hover":"reference-compact-hover")).values.options.islandHoverLayout:null}}
                Component {id:classic;Item {
                    Text {anchors.centerIn:parent;text:"15:58";font.family:Theme.fontFamily;font.pixelSize:48;font.bold:true;color:Theme.text}
                    Text {anchors.left:parent.left;anchors.leftMargin:50;anchors.verticalCenter:parent.verticalCenter;text:"M   T   W   T   F";font.pixelSize:25;color:Theme.accent}
                }}
            }
        }
    }
    SettingSlider {visible:SettingsService.islandHoverDesign!=="classic";label:Tr.t("Clock size · bar and hover");from:10;to:64;unit:" px";value:SettingsService.islandClockSize;onMoved:value=>SettingsService.setSharedClockSize(value)}
    SettingRow {
        visible:SettingsService.islandHoverDesign!=="classic"
        label:Tr.t("Carry bar date into hover view")
        reading:Tr.t("Follow the bar’s date visibility and move the same date into its chosen position.")
        ToggleSwitch{checked:SettingsService.islandHoverDateFollowBar;onToggled:checked=>SettingsService.set("islandHoverDateFollowBar",checked)}
    }
    SettingRow {
        visible:SettingsService.islandHoverDesign!=="classic"
        label:Tr.t("Date position")
        ThemedComboBox {model:[{id:"top",name:Tr.t("Top")},{id:"bottom",name:Tr.t("Bottom")},{id:"left",name:Tr.t("Left")},{id:"right",name:Tr.t("Right")},{id:"hidden",name:Tr.t("Hidden")}];textRole:"name";currentIndex:Math.max(0,model.findIndex(item=>item.id===SettingsService.islandHoverDatePosition));onActivated:index=>SettingsService.set("islandHoverDatePosition",model[index].id)}
    }
    Repeater {
        model:SettingsService.islandHoverDesign!=="classic"?[{key:"islandHoverTopLeft",label:"Top-left content"},{key:"islandHoverTopRight",label:"Top-right content"}]:[]
        delegate:SettingRow {
            required property var modelData
            label:Tr.t(modelData.label)
            ThemedComboBox {model:root.headerChoices;textRole:"name";currentIndex:Math.max(0,model.findIndex(item=>item.id===SettingsService[modelData.key]));onActivated:index=>SettingsService.set(modelData.key,model[index].id)}
        }
    }
    SettingRow {
        visible:SettingsService.islandHoverDesign!=="classic"
        label:Tr.t("Hide media player when nothing is playing")
        reading:Tr.t("Hide the mini player while playback is paused or stopped.")
        ToggleSwitch {
            checked:SettingsService.islandHoverMediaAutoHide
            onToggled:checked=>SettingsService.set("islandHoverMediaAutoHide",checked)
        }
    }

}
