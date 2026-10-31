import "../../" as Config
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
import "../../theme"
import "../../services"
import "../../components"

FocusScope {
    id:root
    implicitWidth:carouselMode?940:860
    implicitHeight:carouselMode?196:620
    signal closed()
    property string scope:"setup"
    property string moduleId:"notes"
    property string query:""
    property string message:""
    property int currentIndex:0
    readonly property bool carouselMode:SettingsService.presetLibraryCarousel
    readonly property var scopes:[
        {id:"setup",name:Tr.t("Full setups"),key:1},
        {id:"bar",name:Tr.t("Bar"),key:2},
        {id:"barcolour",name:Tr.t("Bar Colour"),key:9},
        {id:"macglass",name:Tr.t("MacShell glass"),key:0},
        {id:"launcher",name:Tr.t("Launcher"),key:3},
        {id:"modules",name:Tr.t("Modules"),key:4},
        {id:"designs",name:Tr.t("Designs"),key:5},
        {id:"lockscreen",name:Tr.t("Lock designs"),key:-1},
        {id:"lockmotion",name:Tr.t("Lock"),key:6},
        {id:"shellmotion",name:Tr.t("Shell"),key:7},
        {id:"windowmotion",name:Tr.t("Windows"),key:8}
    ]
    readonly property int categoryIndex:Math.max(0,scopes.findIndex(s=>s.id===root.scope))
    readonly property var moduleChoices:[{id:"all",name:Tr.t("All")}].concat(ModulePresetService.modules)
    function modulePresets():var {
        if(root.moduleId!=="all")return ModulePresetService.list(root.moduleId)
        let all=[]
        for(const module of ModulePresetService.modules)all=all.concat(ModulePresetService.list(module.id).map(p=>Object.assign({},p,{id:module.id+"/"+p.id,moduleId:module.id,name:module.name+" · "+p.name})))
        return all
    }
    readonly property string moduleName:ModulePresetService.modules.find(m=>m.id===root.moduleId)?.name||root.moduleId
    function libraryFor(kind:string):var {
        const library=kind==="setup"?SetupPresetService.saved.concat(SetupPresetService.designs)
            :kind==="bar"?IslandPresetService.saved.concat(IslandPresetService.designs)
            :kind==="barcolour"?BarColourService.designs
            :kind==="macglass"?MacGlassPresetService.saved.concat(MacGlassPresetService.designs)
            :kind==="launcher"?LauncherPresetService.saved.concat(LauncherPresetService.designs)
            :kind==="designs"?SettingsDesignService.saved.concat(SettingsDesignService.designs)
            :kind==="lockscreen"?Config.LockDesignPresetService.saved.concat(Config.LockDesignPresetService.designs)
            :kind==="lockmotion"?LockAnimationPresetService.saved.concat(LockAnimationPresetService.designs)
            :kind==="shellmotion"?Theme.motionPresets.map(p=>({id:p.id,name:p.label,values:p}))
            :kind==="windowmotion"?Motion.presets.map(p=>({id:p.id,name:p.label,description:p.note,values:p}))
            :root.modulePresets()
        return library.filter(p=>[p.name,p.description||"",kind,kind==="modules"?root.moduleName:""].join(" ").toLocaleLowerCase().includes(root.query.trim().toLocaleLowerCase()))
    }
    readonly property var catalogue:root.scopes.map(s=>root.libraryFor(s.id))
    readonly property var presets:root.catalogue[root.categoryIndex]||[]
    readonly property var selected:root.presets[root.currentIndex]||null
    function stable(value:var):string {
        if(value===undefined)return "null"
        if(value===null||typeof value!=="object")return JSON.stringify(value)
        if(Array.isArray(value))return "["+value.map(v=>root.stable(v)).join(",")+"]"
        return "{"+Object.keys(value).sort().map(k=>JSON.stringify(k)+":"+root.stable(value[k])).join(",")+"}"
    }
    readonly property string currentSignature:!root.visible||IslandPresetService.applying?"":root.scope==="setup"?root.stable(SetupPresetService.capture()):root.scope==="modules" && root.moduleId!=="all"?root.stable(ModulePresetService.capture(root.moduleId)):""
    function applied(p:var):bool {
        if(!root.visible||IslandPresetService.applying||!p || (scope==="modules" && root.moduleId==="all"))return false
        if(scope==="bar")return IslandPresetService.matches(p.values)
        if(scope==="barcolour")return BarColourService.matches(p.values)
        if(scope==="macglass")return MacGlassPresetService.matches(p.values)
        if(scope==="launcher")return LauncherPresetService.matches(p.values)
        if(scope==="lockscreen")return Config.LockDesignPresetService.matches(p.values)
        if(scope==="lockmotion")return LockAnimationPresetService.matches(p.values)
        if(scope==="shellmotion")return SettingsService.motionScale===p.values.scale && SettingsService.motionCurve===p.values.curve
        if(scope==="windowmotion")return SettingsService.animationPreset===p.id
        if(scope==="designs")return Object.keys(p.values).every(k=>SettingsDesignService.style[k]===p.values[k])
        return root.stable(p.values)===root.currentSignature
    }
    function syncSelection():void {
        const active=root.presets.findIndex(p=>root.applied(p))
        root.currentIndex=active>=0?active:0
    }
    function activate():void {root.message="";root.syncSelection();Qt.callLater(()=>root.forceActiveFocus())}
    function deactivate():void {}
    function navigationStatus():var {return {mode:root.carouselMode?"carousel":"menu",module:root.moduleId,category:root.scope,index:root.currentIndex,count:root.presets.length,selected:root.selected?.id||"",position:carouselHost.item?.activeStrip?.position??-1,frames:carouselHost.item?.activeStrip?.frameStats?.()||{},categories:root.scopes.map(s=>s.id)}}
    function browse(direction:string):void {if(direction==="all" && root.scope==="modules")root.moduleId="all";else if(direction==="up")root.turn(-1);else if(direction==="down")root.turn(1);else if(direction==="left")root.step(-1);else if(direction==="right")root.step(1)}
    function turn(delta:int):void {
        const next=Math.max(0,Math.min(root.scopes.length-1,root.categoryIndex+delta))
        root.scope=root.scopes[next].id
        root.forceActiveFocus()
    }
    function step(delta:int):void {
        if(!root.presets.length)return
        root.currentIndex=(root.currentIndex+delta+root.presets.length)%root.presets.length
    }
    function applyPreset(p:var):void {
        if(!p||!SettingsService.arrived)return
        const kind=root.scope, module=p.moduleId||root.moduleId
        root.closed()
        Qt.callLater(()=>{
            if(kind==="bar")IslandPresetService.apply(p.values,p.id)
            else if(kind==="barcolour")BarColourService.apply(p.values)
            else if(kind==="macglass")MacGlassPresetService.apply(p.values)
            else if(kind==="launcher")LauncherPresetService.apply(p.values)
            else if(kind==="setup")SetupPresetService.apply(p.values)
            else if(kind==="designs")SettingsDesignService.apply(p.values)
            else if(kind==="lockscreen")Config.LockDesignPresetService.apply(p.values)
            else if(kind==="lockmotion")LockAnimationPresetService.apply(p.values)
            else if(kind==="shellmotion"){SettingsService.set("gameMode",false);SettingsService.set("motionScale",p.values.scale);SettingsService.set("motionCurve",p.values.curve)}
            else if(kind==="windowmotion")SettingsService.set("animationPreset",p.id)
            else ModulePresetService.apply(module,p.values)
        })
    }
    onScopeChanged:Qt.callLater(root.syncSelection)
    onPresetsChanged:Qt.callLater(root.syncSelection)
    onCarouselModeChanged:Qt.callLater(()=>root.forceActiveFocus())
    Component.onCompleted:root.activate()
    Keys.onPressed:event=>{
        if(event.key>=Qt.Key_0 && event.key<=Qt.Key_9 && !(event.modifiers&(Qt.ControlModifier|Qt.AltModifier|Qt.MetaModifier))){
            const found=root.scopes.find(s=>s.key===event.key-Qt.Key_0)
            if(found){root.scope=found.id;event.accepted=true}
        }
    }
    Keys.onEscapePressed:root.closed()
    Keys.onLeftPressed:root.step(-1)
    Keys.onRightPressed:root.step(1)
    Keys.onUpPressed:root.turn(-1)
    Keys.onDownPressed:root.turn(1)
    Keys.onReturnPressed:root.applyPreset(root.selected)
    Keys.onEnterPressed:root.applyPreset(root.selected)

    // Text-only dropdown occupies the same location as the bar changer's filter.
    TextMetrics {id:categoryWidth;font:categoryButton.font;text:categoryButton.displayText}
    ThemedComboBox {
        id:categoryButton
        visible:root.carouselMode
        x:0;y:4;width:categoryWidth.width+20;height:20;z:30
        leftPadding:0;rightPadding:20;focusPolicy:Qt.NoFocus
        popup.focus:false;popup.width:190;popup.onOpened:root.forceActiveFocus()
        model:root.scopes;textRole:"name";currentIndex:root.categoryIndex
        font.pixelSize:Theme.fontSizeSmall;background:Item{}
        indicator:Text {x:categoryButton.width-width-2;y:(categoryButton.height-height)/2;text:"󰅀";font.family:Theme.fontMono;font.pixelSize:11;color:categoryButton.popup.visible?Theme.moduleColour("presets","accent",Theme.accent):Theme.moduleColour("presets","muted",Theme.textMuted)}
        onActivated:{root.scope=model[currentIndex].id;root.forceActiveFocus()}
    }
    ThemedComboBox {
        visible:root.carouselMode && root.scope==="modules"
        anchors.right:parent.right;y:4;width:180;height:22;z:30
        model:root.moduleChoices;textRole:"name";focusPolicy:Qt.NoFocus
        currentIndex:Math.max(0,model.findIndex(m=>m.id===root.moduleId))
        onActivated:{root.moduleId=model[currentIndex].id;root.forceActiveFocus()}
    }
    Row {
        visible:root.carouselMode && root.scope!=="modules"
        anchors.right:parent.right;y:0;z:35;spacing:8
        PillButton {text:Tr.t("Auto-hide");active:SettingsService.barAutoHide;onClicked:SettingsService.set("barAutoHide",!SettingsService.barAutoHide)}
        PillButton {text:Tr.t("Smart auto-hide");active:SettingsService.barAutoHideSmart;onClicked:SettingsService.set("barAutoHideSmart",!SettingsService.barAutoHideSmart)}
    }
    Loader {
        id:carouselHost
        anchors.fill:parent;anchors.topMargin:40;active:root.carouselMode
        sourceComponent:PresetLibraryCarousel {
            applied:p=>root.applied(p);categories:root.scopes;catalogue:root.catalogue;categoryIndex:root.categoryIndex;currentIndex:root.currentIndex;moduleId:root.moduleId
            onSelected:index=>root.currentIndex=index
            onActivated:preset=>root.applyPreset(preset)
            onTurn:delta=>root.turn(delta)
        }
    }
    Loader {
        anchors.fill:parent;active:!root.carouselMode
        sourceComponent:ColumnLayout {
            spacing:12
            RowLayout {
                Layout.fillWidth:true
                Text {Layout.fillWidth:true;text:Tr.t("Preset library");font.family:Theme.fontFamily;font.pixelSize:23;font.weight:Font.DemiBold;color:Theme.moduleColour("presets","foreground",Theme.text)}
                PillButton {text:Tr.t("Auto-hide");active:SettingsService.barAutoHide;onClicked:SettingsService.set("barAutoHide",!SettingsService.barAutoHide)}
                PillButton {text:Tr.t("Smart auto-hide");active:SettingsService.barAutoHideSmart;onClicked:SettingsService.set("barAutoHideSmart",!SettingsService.barAutoHideSmart)}
                IconButton {icon:"󰅖";onClicked:root.closed()}
            }
            Flow {
                Layout.fillWidth:true;spacing:6
                Repeater {model:root.scopes;PillButton {required property var modelData;text:modelData.key+" · "+modelData.name;active:root.scope===modelData.id;onClicked:{root.scope=modelData.id;root.forceActiveFocus()}}}
                ThemedComboBox {visible:root.scope==="modules";width:210;model:root.moduleChoices;textRole:"name";focusPolicy:Qt.NoFocus;currentIndex:Math.max(0,model.findIndex(m=>m.id===root.moduleId));onActivated:{root.moduleId=model[currentIndex].id;root.forceActiveFocus()}}
            }
            Controls.TextField {
                id:search
                Layout.fillWidth:true;Layout.preferredHeight:38
                placeholderText:Tr.t("Search presets…");text:root.query;onTextEdited:root.query=text
                onAccepted:root.applyPreset(root.selected)
                font.family:Theme.fontFamily;font.pixelSize:13;color:Theme.moduleColour("presets","foreground",Theme.text);selectionColor:Theme.moduleColour("presets","accent",Theme.accent);selectedTextColor:Theme.accentText
                background:Rectangle {radius:10;color:Theme.islandSurface;border.width:1;border.color:search.activeFocus?Theme.moduleColour("presets","accent",Theme.accent):Theme.border}
                Keys.onDownPressed:{root.forceActiveFocus();root.turn(1)}
                Keys.onUpPressed:{root.forceActiveFocus();root.turn(-1)}
            }
            GridView {
                id:grid
                Layout.fillWidth:true;Layout.fillHeight:true;clip:true;cacheBuffer:0;reuseItems:true
                model:root.presets;currentIndex:root.currentIndex;keyNavigationEnabled:false
                cellWidth:width/(width>=700?4:width>=500?3:2);cellHeight:230
                boundsBehavior:Flickable.StopAtBounds
                onCurrentIndexChanged:if(currentIndex>=0)positionViewAtIndex(currentIndex,GridView.Contain)
                Controls.ScrollBar.vertical:Controls.ScrollBar{}
                delegate:Item {
                    id:card
                    required property var modelData
                    required property int index
                    width:grid.cellWidth;height:grid.cellHeight
                    property bool pooled:false
                    GridView.onPooled:pooled=true
                    GridView.onReused:pooled=false
                    readonly property bool chosen:root.currentIndex===index
                    Rectangle {
                        anchors.fill:parent;anchors.margins:6;radius:16;color:Theme.surface;border.width:card.chosen?2:1;border.color:card.chosen?Theme.moduleColour("presets","accent",Theme.accent):Theme.border
                        ColumnLayout {
                            anchors.fill:parent;anchors.margins:12;spacing:8
                            PresetVisual {Layout.fillWidth:true;Layout.preferredHeight:110;kind:root.scope;moduleId:card.modelData.moduleId||root.moduleId;values:card.modelData.values;animate:!card.pooled&&card.y+card.height>grid.contentY&&card.y<grid.contentY+grid.height}
                            Text {Layout.fillWidth:true;text:card.modelData.name;font.family:Theme.fontFamily;font.pixelSize:14;font.weight:Font.DemiBold;color:Theme.moduleColour("presets","foreground",Theme.text);elide:Text.ElideRight}
                            Text {Layout.fillWidth:true;Layout.fillHeight:true;text:card.modelData.description||"";font.family:Theme.fontFamily;font.pixelSize:11;color:Theme.moduleColour("presets","muted",Theme.textMuted);maximumLineCount:2;wrapMode:Text.WordWrap;elide:Text.ElideRight}
                            PillButton {text:Tr.t("Apply");active:card.chosen;onClicked:root.applyPreset(card.modelData)}
                        }
                        TapHandler {onTapped:{root.currentIndex=card.index;root.forceActiveFocus()}}
                    }
                }
                Text {anchors.centerIn:parent;visible:!grid.count;text:Tr.t("No presets match this search.");font.family:Theme.fontFamily;font.pixelSize:13;color:Theme.moduleColour("presets","muted",Theme.textMuted)}
            }
            Text {text:Tr.t("Up/down: categories · Left/right: presets · Enter: apply · Esc: close");font.family:Theme.fontFamily;font.pixelSize:11;color:Theme.moduleColour("presets","muted",Theme.textMuted)}
        }
    }
}
