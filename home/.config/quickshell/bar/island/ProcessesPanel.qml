import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../services"
import "../../components"
ColumnLayout {
    id:root
    property string category:"apps"
    property string sortBy:"memory"
    property string filter:""
    property string pending:""
    property bool force:false
    signal closed()
    readonly property var rows:ProcessesService.entries.filter(e=>(category==="all"||e.kind===category)&&e.name.toLowerCase().includes(filter.toLowerCase())).sort((a,b)=>sortBy==="name"?a.name.localeCompare(b.name):(b[sortBy]-a[sortBy]))
    spacing:12
    Component.onCompleted:ProcessesService.subscribe()
    Component.onDestruction:ProcessesService.release()
    RowLayout{Layout.fillWidth:true
        Text{text:Tr.t("Processes");font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeLarge;font.weight:Font.DemiBold;color:Theme.moduleColour("processes","foreground",Theme.text)}
        Item{Layout.fillWidth:true}
        Text{text:ProcessesService.memory(ProcessesService.available)+" "+Tr.t("available");font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSmall;color:Theme.moduleColour("processes","muted",Theme.textMuted)}
        PillButton{text:Tr.t("Refresh");onClicked:ProcessesService.refresh()}
    }
    RowLayout{Layout.fillWidth:true
        SegmentedControl{options:[{id:"apps",label:Tr.t("Apps")},{id:"background",label:Tr.t("Background")},{id:"all",label:Tr.t("All")}];current:root.category;onSelected:id=>root.category=id}
        Item{Layout.fillWidth:true}
        ThemedComboBox{Layout.preferredWidth:140;model:[{id:"memory",name:Tr.t("Memory")},{id:"cpu",name:Tr.t("CPU")},{id:"name",name:Tr.t("Name")}];textRole:"name";currentIndex:model.findIndex(p=>p.id===root.sortBy);onActivated:root.sortBy=model[currentIndex].id}
    }
    Rectangle{Layout.fillWidth:true;implicitHeight:34;radius:Theme.radiusSmall;color:Theme.islandSurface;border.width:1;border.color:Theme.border
        TextInput{anchors.fill:parent;anchors.leftMargin:12;anchors.rightMargin:12;verticalAlignment:TextInput.AlignVCenter;selectByMouse:true;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeRegular;color:Theme.moduleColour("processes","foreground",Theme.text);onTextEdited:root.filter=text
            Text{anchors.verticalCenter:parent.verticalCenter;visible:parent.text==="";text:Tr.t("Filter processes…");font:parent.font;color:Theme.moduleColour("processes","muted",Theme.textMuted)}
        }
    }
    ListView{
        Layout.fillWidth:true;Layout.fillHeight:true;clip:true;spacing:5;reuseItems:true
        model:ScriptModel{values:root.rows}
        delegate:Rectangle{
            required property var modelData
            width:ListView.view.width;height:58;radius:Theme.radiusSmall;color:Theme.islandSurface
            RowLayout{anchors.fill:parent;anchors.margins:10;spacing:10
                ColumnLayout{Layout.fillWidth:true;spacing:2
                    Text{Layout.fillWidth:true;text:modelData.name;textFormat:Text.PlainText;elide:Text.ElideRight;color:Theme.moduleColour("processes","foreground",Theme.text);font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeRegular}
                    Text{text:modelData.processes.length+" "+Tr.t("processes")+(modelData.protected?" · "+Tr.t("System service"):"");color:Theme.moduleColour("processes","muted",Theme.textMuted);font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeLabel}
                }
                Text{Layout.preferredWidth:88;text:ProcessesService.memory(modelData.memory);horizontalAlignment:Text.AlignRight;color:Theme.moduleColour("processes","foreground",Theme.text);font.family:Theme.fontMono;font.pixelSize:Theme.fontSizeSmall}
                Text{Layout.preferredWidth:55;text:modelData.cpu.toFixed(1)+"%";horizontalAlignment:Text.AlignRight;color:Theme.moduleColour("processes","muted",Theme.textMuted);font.family:Theme.fontMono;font.pixelSize:Theme.fontSizeSmall}
                PillButton{visible:!modelData.protected;text:root.pending===modelData.id&&!root.force?Tr.t("Confirm"):Tr.t("Close");onClicked:{if(root.pending===modelData.id&&!root.force){ProcessesService.close(modelData,false);root.pending=""}else{root.pending=modelData.id;root.force=false}}}
                PillButton{visible:!modelData.protected;text:root.pending===modelData.id&&root.force?Tr.t("Confirm"):Tr.t("Force");onClicked:{if(root.pending===modelData.id&&root.force){ProcessesService.close(modelData,true);root.pending=""}else{root.pending=modelData.id;root.force=true}}}
            }
        }
    }
    Text{Layout.fillWidth:true;text:ProcessesService.message||Tr.t("Memory totals account for shared pages. Close requests a normal exit; Force terminates immediately.");font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSmall;color:Theme.moduleColour("processes","muted",Theme.textMuted);wrapMode:Text.WordWrap}
}
