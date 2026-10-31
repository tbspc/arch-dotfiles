import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
import "../../theme"
import "../../services"
import "../../components"
FocusScope {
    id: root
    signal closed()
    property int categoryIndex: 0
    property int stripRevision:0
    property string styleFilter: "all"
    property var library: []
    property string deleting: ""
    readonly property string appliedId:IslandPresetService.activePresetId
    function reloadLibrary(): void { library=SettingsService.copy(IslandPresetService.saved.concat(IslandPresetService.designs)) }
    readonly property var categories: [{id:"floating",name:"Floating"},{id:"notched",name:"Notched"},{id:"chips",name:"Chips"}]
    readonly property var activeStrip: {const revision=stripRevision;return pages.itemAt(categoryIndex)?.strip||null}
    readonly property var selected: activeStrip?.model[activeStrip.current] || null
    function step(delta: int): void {
        if (activeStrip?.count) activeStrip.goTo((activeStrip.current+delta+activeStrip.count)%activeStrip.count)
    }
    function turn(delta: int): void { categoryIndex=Math.max(0,Math.min(categories.length-1,categoryIndex+delta)) }
    function apply(): void {
        if (selected) {
            const preset=selected
            if(!IslandPresetService.matches(preset.values) || Object.keys(SettingsService.moduleElements.bar||{}).length)IslandPresetService.apply(preset.values,preset.id)
            root.closed()
        }
    }
    function syncToActive(fast:bool):void {
        const active=(fast?library.find(p=>p.id===IslandPresetService.activePresetId):null)||IslandPresetService.activeEntry()
        if(active){
            IslandPresetService.rememberActive(active.id)
            const category=IslandPresetService.categoryOf(active.values)
            categoryIndex=Math.max(0,categories.findIndex(c=>c.id===category))
            if(!IslandPresetService.select(library,category,styleFilter).some(item=>item.id===active.id))styleFilter="all"
            Qt.callLater(()=>{
                const strip=pages.itemAt(root.categoryIndex)?.strip
                if(!strip)return
                const index=strip.model.findIndex(item=>item.id===active.id)
                if(index>=0){strip.ready=false;strip.goTo(index);strip.position=Qt.binding(()=>strip.current);strip.ready=true}
            })
        }else categoryIndex=SettingsService.islandChipsEnabled?2:SettingsService.notched?1:0
    }
    function deactivate():void{selectionReset.restart()}
    function activate(): void {
        selectionReset.stop()
        const next=IslandPresetService.saved.concat(IslandPresetService.designs)
        if (JSON.stringify(next)!==JSON.stringify(library)) library=SettingsService.copy(next)
        syncToActive()
        Qt.callLater(()=>root.forceActiveFocus())
    }
    Timer{id:selectionReset;interval:Theme.durationMorph;onTriggered:root.syncToActive(true)}
    Timer{id:initialSelection;interval:0;onTriggered:root.syncToActive()}
    Component.onCompleted: {
        library=SettingsService.copy(IslandPresetService.saved.concat(IslandPresetService.designs))
        initialSelection.restart()
    }
    Keys.onLeftPressed:{barFilter.popup.close();step(-1)}
    Keys.onRightPressed:{barFilter.popup.close();step(1)}
    Keys.onUpPressed:{barFilter.popup.close();turn(-1)}
    Keys.onDownPressed:{barFilter.popup.close();turn(1)}
    Keys.onReturnPressed:apply()
    Keys.onEnterPressed:apply()
    Keys.onEscapePressed:closed()
    TextMetrics{id:filterWidth;font:barFilter.font;text:barFilter.displayText}
    ThemedComboBox {
        id:barFilter
        x:0;y:4;width:filterWidth.width+20;height:20;z:30
        leftPadding:0;rightPadding:20
        focusPolicy:Qt.NoFocus
        popup.focus:false
        popup.onOpened:root.forceActiveFocus()
        popup.width:150
        indicator:Text{x:barFilter.width-width-2;y:(barFilter.height-height)/2;text:"󰅀";font.family:Theme.fontMono;font.pixelSize:11;color:barFilter.popup.visible?Theme.moduleColour("barpresets","accent",Theme.accent):Theme.moduleColour("barpresets","muted",Theme.textMuted)}
        model:[{id:"all",label:Tr.t("All")},{id:"minimal",label:Tr.t("Minimal")},{id:"compact",label:Tr.t("Compact")},{id:"expanded",label:Tr.t("Expanded")}]
        textRole:"label"
        font.pixelSize:Theme.fontSizeSmall
        currentIndex:Math.max(0,model.findIndex(item=>item.id===root.styleFilter))
        background:Item{}
        onActivated:{root.styleFilter=model[currentIndex].id;Qt.callLater(()=>root.forceActiveFocus())}
    }
    Row {
        visible:true
        anchors.right:parent.right;y:0;z:35;spacing:8
        PillButton {text:Tr.t("Auto-hide");active:SettingsService.barAutoHide;onClicked:SettingsService.set("barAutoHide",!SettingsService.barAutoHide)}
        PillButton {text:Tr.t("Smart auto-hide");active:SettingsService.barAutoHideSmart;onClicked:SettingsService.set("barAutoHideSmart",!SettingsService.barAutoHideSmart)}
    }
    ColumnLayout { objectName:"design:BarPresetPanel:1";
        anchors.fill:parent;anchors.topMargin:40
        spacing:12
        Item { objectName:"design:BarPresetPanel:6";
            id:viewport
            Layout.fillWidth:true;Layout.fillHeight:true
            Layout.minimumHeight:Math.ceil(100*1.25)+8
            clip:true
            Repeater {
                id:pages
                model:root.categories
                onItemAdded:{root.stripRevision++;if(initialSelection)initialSelection.restart()}
                onItemRemoved:root.stripRevision++
                Item { objectName:"design:BarPresetPanel:7";
                    id:page
                    required property var modelData
                    required property int index
                    property alias strip:carousel
                    width:viewport.width;height:viewport.height
                    y:(index-root.categoryIndex)*height
                    opacity:index===root.categoryIndex?1:0
                    Behavior on y{NumberAnimation{duration:Theme.durationMorph;easing.type:Theme.easing}}
                    Behavior on opacity{NumberAnimation{duration:Theme.durationMorph;easing.type:Theme.easing}}
                    Carousel {
                        id:carousel
                        anchors.fill:parent
                        model:IslandPresetService.select(root.library,page.modelData.id,root.styleFilter)
                        tileWidth:160;tileHeight:100;centreScale:1.25;gap:12;virtualized:true;reach:2.5
                        onModelChanged:Qt.callLater(()=>{if(carousel.count)carousel.goTo(Math.min(carousel.current,carousel.count-1))})
                        onActivated:root.apply()
                        delegate:CarouselTile {
                            id:tile
                            IslandPresetPreview {
                                anchors.fill:parent;values:tile.modelData.values;layer.enabled:true;layer.smooth:true;layer.textureSize:Qt.size(200,125);border.width:tile.centred?2:1;border.color:tile.centred?Theme.moduleColour("barpresets","accent",Theme.accent):Theme.border
                                AppliedMark{visible:tile.modelData.id===root.appliedId}
                                Rectangle{ objectName:"design:BarPresetPanel:8";anchors.left:parent.left;anchors.right:parent.right;anchors.bottom:parent.bottom;height:23;color:"#a0000000";radius:Theme.radiusSmall}
                                Text{ objectName:"design:BarPresetPanel:9";anchors.bottom:parent.bottom;anchors.bottomMargin:5;anchors.horizontalCenter:parent.horizontalCenter;width:parent.width-10;text:tile.modelData.name;elide:Text.ElideRight;horizontalAlignment:Text.AlignHCenter;font.family:Theme.fontFamily;font.pixelSize:10;color:Theme.moduleColour("barpresets","foreground",Theme.text)}
                            }
                        }
                    }
                }
            }
        }
        RowLayout { objectName:"design:BarPresetPanel:10";
            Layout.fillWidth:true
            spacing:12
            Text{ objectName:"design:BarPresetPanel:11";Layout.fillWidth:true;text:Tr.t(root.categories[root.categoryIndex].name);font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSmall;color:Theme.moduleColour("barpresets","muted",Theme.textMuted);elide:Text.ElideRight}
            Text{ objectName:"design:BarPresetPanel:12";text:root.activeStrip?.count?`${root.activeStrip.current+1}/${root.activeStrip.count}`:"";font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSmall;color:Theme.moduleColour("barpresets","muted",Theme.textMuted)}
            Text { objectName:"design:BarPresetPanel:13";
                text:"󰅃";visible:root.categoryIndex>0;font.family:Theme.fontMono;font.pixelSize:Theme.fontSizeRegular;color:upMouse.containsMouse?Theme.moduleColour("barpresets","foreground",Theme.text):Theme.moduleColour("barpresets","muted",Theme.textMuted)
                Behavior on color{ColorAnimation{duration:Theme.durationFast}}
                MouseArea{id:upMouse;anchors.fill:parent;anchors.margins:-6;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:root.turn(-1)}
            }
            Text { objectName:"design:BarPresetPanel:14";
                text:"󰅀";visible:root.categoryIndex<root.categories.length-1;font.family:Theme.fontMono;font.pixelSize:Theme.fontSizeRegular;color:downMouse.containsMouse?Theme.moduleColour("barpresets","foreground",Theme.text):Theme.moduleColour("barpresets","muted",Theme.textMuted)
                Behavior on color{ColorAnimation{duration:Theme.durationFast}}
                MouseArea{id:downMouse;anchors.fill:parent;anchors.margins:-6;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:root.turn(1)}
            }
        }
    }
    component AppliedMark:Rectangle {
        anchors.top:parent.top;anchors.right:parent.right;anchors.margins:6
        width:18;height:18;radius:9;color:Theme.moduleColour("barpresets","accent",Theme.accent)
        Text{anchors.centerIn:parent;text:"󰄬";font.family:Theme.fontMono;font.pixelSize:10;color:Theme.accentText}
    }

}
