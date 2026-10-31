import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"
import "../services"
import "../components"
import "../bar/widgets"
import "../bar/island"

PanelWindow {
    id:root
    property bool shown:false
    property string selected:"bar"
    property string controlsTab:"elements"
    property var initialStyles:({})
    property var initialRounding:({})
    property var initialElements:({})
    property var initialChips:({})
    property var initialIsland:({})
    property bool initialChipMode:false
    property var selectedElement:null
    property string selectedChip:""
    property string selectedControl:""
    property string pendingSelection:""
    property var elements:[]
    readonly property var targetElements:selected!=="bar"?elements:elements.filter(item=>{
        const name=item.objectName||""
        let owner=item;while(owner){if(!owner.visible)return false;owner=owner.parent}
        return typeof item.chipId==="string" || typeof item.mediaAction==="string" || name.startsWith("island-") && name!=="island-clock" || ["design:ClockModule:6","design:ClockModule:8","design:media-artwork","design:media-spectrum"].includes(name)
    })
    property var previewItem:null
    property var selectionOutline:null
    readonly property var style:SettingsService.moduleAppearance[selected]||({})
    readonly property var elementStyle:selectedElement?(SettingsService.moduleElements[selected]||{})[ModuleService.elementKey(selectedElement)]||({}):({})
    readonly property var chipStyle:selectedChip?IslandChipService.get(selectedChip):({})
    readonly property var controlStyle:chipStyle.controls?.[selectedControl]||({})
    readonly property var entries:{
        const list=[{id:"bar",name:"Bar / Island"}]
        for(const entry of ModuleService.catalogue)
            if(entry.width>0 && entry.id!=="pet" && entry.id!=="clock" && !list.some(i=>i.id===entry.id))list.push({id:entry.id,name:entry.name})
        for(const entry of ControlsService.doors)
            if(entry.panel && !list.some(i=>i.id===entry.panel))list.push({id:entry.panel,name:entry.label})
        if(!list.some(i=>i.id==="sound"))list.push({id:"sound",name:"Sound controls"})
        if(!list.some(i=>i.id==="controls"))list.push({id:"controls",name:"Control centre"})
        if(!list.some(i=>i.id==="summary"))list.push({id:"summary",name:"Calendar and media"})
        return list
    }
    onSelectedChanged:{selectedElement=null;selectedChip="";selectedControl="";elements=[]}
    function open(output:var):void {
        if(output)root.screen=output
        const next=SettingsService.copy(SettingsService.moduleElements)||{}
        if(next.bar?.["island-clock"]){
            next.bar["design:ClockModule:6"]=Object.assign({},next.bar["island-clock"],next.bar["design:ClockModule:6"]||{})
            delete next.bar["island-clock"]
            SettingsService.set("moduleElements",next)
        }
        remember()
        shown=true
    }
    function remember():void {
        initialStyles=SettingsService.copy(SettingsService.moduleAppearance)||{}
        initialRounding=SettingsService.copy(SettingsService.moduleRounding)||{}
        initialElements=SettingsService.copy(SettingsService.moduleElements)||{}
        initialChips=SettingsService.copy(SettingsService.islandChipSettings)||{}
        initialChipMode=SettingsService.islandChipsEnabled
        initialIsland=IslandPresetService.capture()
    }
    function close():void{selectedElement=null;previewItem=null;shown=false}
    function resetModule(id:string):void {
        selectedElement=null;selectedChip="";selectedControl=""
        for(const key of ["moduleElements","moduleAppearance","moduleRounding"]){
            const next=SettingsService.copy(SettingsService[key])||{};delete next[id];SettingsService.set(key,next)
        }
        if(id==="launcher")SettingsService.set("launcherStyle",{})
        if(id==="bar"){
            const active=IslandPresetService.activeEntry()
            if(active)IslandPresetService.apply(active.values)
        }
    }
    function undo():void {
        selectedElement=null
        SettingsService.set("moduleAppearance",initialStyles)
        SettingsService.set("moduleRounding",initialRounding)
        SettingsService.set("moduleElements",initialElements)
        SettingsService.set("islandChipSettings",initialChips)
        SettingsService.set("islandChipsEnabled",initialChipMode)
        for(const key of IslandPresetService.keys)SettingsService.set(key,initialIsland[key])
    }
    function setStyle(key:string,value:var):void {
        const next=SettingsService.copy(SettingsService.moduleAppearance)||{}
        next[selected]=Object.assign({},next[selected]||{},{[key]:value})
        SettingsService.set("moduleAppearance",next)
    }
    function boundsFor(item:var):var {
        let owner=item?.parent
        while(owner){
            if(selected==="bar" && selectedControl && typeof owner.chipId==="string")return owner
            if(selected==="bar" && !selectedChip && owner.objectName==="design:IslandRest:1")return owner
            owner=owner.parent
        }
        return previewItem
    }
    function constrainedPosition(item:var,key:string,value:real,old:real):real {
        const box=boundsFor(item)
        if(!item||!item.parent||!box)return value
        const corners=[item.mapToItem(box,0,0),item.mapToItem(box,item.width,0),item.mapToItem(box,0,item.height),item.mapToItem(box,item.width,item.height)]
        const horizontal=key==="x"||key==="offsetX"
        const points=corners.map(p=>horizontal?p.x:p.y)
        const a=item.parent.mapToItem(box,0,0),b=item.parent.mapToItem(box,horizontal?1:0,horizontal?0:1)
        const factor=Math.max(.001,Math.abs(horizontal?b.x-a.x:b.y-a.y))
        const limit=horizontal?box.width:box.height
        const low=old+(2-Math.min(...points))/factor
        const high=old+(limit-2-Math.max(...points))/factor
        return Math.round(low>high?low:Math.max(low,Math.min(high,value)))
    }
    function keepSelectionInside():void {
        const item=selectedElement
        if(!item)return
        if(selectedChip){
            const opts=selectedControl?controlStyle:chipStyle
            const xKey=selectedControl?"x":"offsetX",yKey=selectedControl?"y":"offsetY"
            const x=opts[xKey]??0,y=opts[yKey]??0
            const cx=constrainedPosition(item,xKey,x,x),cy=constrainedPosition(item,yKey,y,y)
            if(cx!==x)setChip(xKey,cx);if(cy!==y)setChip(yKey,cy)
        }else{
            const x=elementStyle.x??0,y=elementStyle.y??0
            const cx=constrainedPosition(item,"x",x,x),cy=constrainedPosition(item,"y",y,y)
            if(cx!==x)setElement("x",cx);if(cy!==y)setElement("y",cy)
        }
    }
    Timer{id:constrainAfterLayout;interval:0;onTriggered:root.keepSelectionInside()}
    function setElement(key:string,value:var):void {
        if(!selectedElement)return
        if(key==="x"||key==="y")value=constrainedPosition(selectedElement,key,value,elementStyle[key]??0)
        if(key==="fontSize" && "font" in selectedElement){
            const box=boundsFor(selectedElement)
            if(box){const a=selectedElement.mapToItem(box,0,0),b=selectedElement.mapToItem(box,selectedElement.width,selectedElement.height)
                const old=Math.max(1,selectedElement.font.pixelSize)
                value=Math.min(value,old*Math.max(1,box.height-4)/Math.max(1,Math.abs(b.y-a.y)))
                if(Math.abs(selectedElement.width-selectedElement.implicitWidth)<1)value=Math.min(value,old*Math.max(1,box.width-4)/Math.max(1,Math.abs(b.x-a.x)))}
        }
        if(key==="widthScale"||key==="heightScale"){
            const box=boundsFor(selectedElement),horizontal=key==="widthScale"
            if(box){const a=selectedElement.mapToItem(box,0,0),b=selectedElement.mapToItem(box,selectedElement.width,selectedElement.height)
                const size=Math.max(.001,Math.abs(horizontal?b.x-a.x:b.y-a.y))
                value=Math.min(value,(elementStyle[key]??100)*Math.max(1,(horizontal?box.width:box.height)-4)/size)}
        }
        const next=SettingsService.copy(SettingsService.moduleElements)||{}
        const id=ModuleService.elementKey(selectedElement)
        next[selected]=Object.assign({},next[selected]||{})
        next[selected][id]=Object.assign({},next[selected][id]||{},{[key]:value})
        SettingsService.set("moduleElements",next)
        if(key!=="x"&&key!=="y")constrainAfterLayout.restart()
    }
    function selectNamed(key:string):void {
        refreshElements()
        const item=elements.find(e=>ModuleService.elementKey(e)===key)
        if(item)choose(item)
    }
    function resetElement():void {
        if(!selectedElement)return
        const next=SettingsService.copy(SettingsService.moduleElements)||{}
        if(next[selected])delete next[selected][ModuleService.elementKey(selectedElement)]
        SettingsService.set("moduleElements",next)
    }
    function setChip(key:string,value:var):void {
        if(!selectedChip)return
        if(selectedElement && ["x","y","offsetX","offsetY"].includes(key))value=constrainedPosition(selectedElement,key,value,(selectedControl?controlStyle:chipStyle)[key]??0)
        if(selectedControl){
            const controls=SettingsService.copy(chipStyle.controls)||{}
            controls[selectedControl]=Object.assign({},controls[selectedControl]||{},{[key]:value})
            IslandChipService.set(selectedChip,"controls",controls)
        }else IslandChipService.set(selectedChip,key,value)
        if(!["x","y","offsetX","offsetY"].includes(key))constrainAfterLayout.restart()
    }
    function choose(item:var):void {
        if(item?.objectName==="island-clock")item=elements.find(e=>e.objectName==="design:ClockModule:6")||item
        selectedChip="";selectedControl=""
        if(selected==="bar"){
            let owner=item,control=null
            while(owner){
                const name=owner.objectName||""
                if(typeof owner.mediaAction==="string"){selectedControl=owner.mediaAction;control=owner}
                if(typeof owner.chipId==="string"){selectedChip=owner.chipId;item=control||owner;break}
                if(["design:media-artwork","design:media-spectrum"].includes(name) || name.startsWith("island-") && name!=="island-clock"){item=owner;break}
                owner=owner.parent
            }
        }
        selectedElement=item;controlsTab="elements"
    }
    function refreshElements():void {
        elements=ModuleService.designElements(previewItem).filter(item=>item.visible && item.width>0 && item.height>0)
        if(pendingSelection){const found=elements.find(e=>ModuleService.elementKey(e)===pendingSelection);if(found){pendingSelection="";choose(found)}}
    }
    function addChip(id:string,x:real):void {
        if(!IslandChipService.ids.includes(id))return
        selectedElement=null;selectedChip="";selectedControl=""
        if(!SettingsService.islandChipsEnabled){
            const side=x<0.5?"left":"right"
            const prefix=({workspaces:"Workspaces",internet:"Internet",bluetooth:"Bluetooth",speaker:"Speaker",battery:"Battery"})[id]
            if(prefix){
                SettingsService.set("island"+prefix,true)
                SettingsService.set("island"+prefix+"Position",side)
                pendingSelection="island-"+id+"-"+side
            }else if(id==="media"){
                const activities=Array.from(SettingsService.islandActivities||SettingsService.besideDefaults||[])
                if(!activities.includes("media"))SettingsService.set("islandActivities",activities.concat(["media"]))
                pendingSelection="design:media-artwork"
            }
            controlsTab="elements"
            return
        }
        selectedChip=id
        const next=SettingsService.copy(SettingsService.islandChipSettings)||{}
        next[id]=Object.assign({},IslandChipService.get(id),{enabled:true,side:x<0.5?"left":"right",offsetX:0,offsetY:0})
        if(id==="media")Object.assign(next[id],{display:"controls",width:150,autoHide:false})
        SettingsService.set("islandChipSettings",next)
        SettingsService.set("islandChipsEnabled",true)
        controlsTab="elements"
    }
    IpcHandler {
        target:"module-design"
        function status():string {
            root.refreshElements()
            return JSON.stringify({shown:root.shown,module:root.selected,chip:root.selectedChip,control:root.selectedControl,elements:root.elements.map(e=>({key:ModuleService.elementKey(e),label:ModuleService.designLabel(e)})),chips:SettingsService.islandChipsEnabled,previewChips:root.previewItem?.configuration?.islandChipsEnabled,previewSettings:root.previewItem?.configuration?.islandChipSettings,previewWidth:root.previewItem?.width,previewHeight:root.previewItem?.height,previewName:root.previewItem?.objectName,selection:root.selectedElement?ModuleService.elementKey(root.selectedElement):"",outline:root.selectionOutline?({x:root.selectionOutline.x,y:root.selectionOutline.y,width:root.selectionOutline.width,height:root.selectionOutline.height}):null,elementStyle:root.elementStyle,chipStyle:root.chipStyle})
        }
        function selectModule(id:string):void{if(root.entries.some(e=>e.id===id))root.selected=id}
        function selectElement(key:string):bool{root.refreshElements();const item=root.elements.find(e=>ModuleService.elementKey(e)===key);if(!item)return false;root.choose(item);return true}
        function edit(key:string,value:string):void{const parsed=JSON.parse(value);if(root.selectedChip)root.setChip(key,parsed);else root.setElement(key,parsed)}
        function addChip(id:string,side:string):void{root.addChip(id,side==="left"?0:1)}
        function resetModule(id:string):void{root.resetModule(id)}
        function resetElement():void{root.resetElement()}
        function undo():void{root.undo()}
        function close():void{root.close()}
    }
    function settingsSection():string {
        if(selected==="bar"||selected==="barpresets")return "island"
        if(selected==="appearance"||selected==="palette")return "appearance"
        if(selected==="launcher")return "launcher"
        if(selected==="controls")return "controls"
        if(["battery","network","wifi","bluetooth","volume","sound"].includes(selected))return "island"
        return "modules"
    }
    visible:shown
    color:Theme.background
    exclusionMode:ExclusionMode.Ignore
    WlrLayershell.namespace:"impasto-module-editor"
    WlrLayershell.layer:WlrLayer.Overlay
    WlrLayershell.keyboardFocus:WlrKeyboardFocus.Exclusive
    anchors{top:true;bottom:true;left:true;right:true}
    Shortcut{sequence:"Escape";context:Qt.WindowShortcut;enabled:root.shown;onActivated:root.close()}
    Connections{target:IslandPresetService;function onAppliedRevisionChanged(){root.selectedElement=null;root.selectedChip="";root.selectedControl="";if(root.shown)root.remember()}}
    Connections{target:LockService;function onLockedChanged(){if(LockService.locked)root.close()}}
    Loader{
        anchors.fill:parent;active:root.shown
        sourceComponent:FocusScope{
            id:stage
            focus:true
            property bool savedPreset:false
            Timer{id:savedNotice;interval:1800;onTriggered:stage.savedPreset=false}
            property string draggingIcon:""
            property point ghost:Qt.point(0,0)
            Image{anchors.fill:parent;source:WallpaperService.currentWallpaper;fillMode:Image.PreserveAspectCrop;asynchronous:true}
            Rectangle{anchors.fill:parent;color:"#77000000"}
            DynamicIsland{id:catalogue;visible:false;active:false}
            Timer{id:elementRefresh;interval:100;onTriggered:root.refreshElements()}
            ColumnLayout{
                anchors.fill:parent;anchors.margins:18;spacing:14
                Rectangle{
                    Layout.fillWidth:true;implicitHeight:54;radius:Theme.radiusMedium;color:Theme.colourIn(QsWindow.window,"cardBackground",Theme.islandGround)
                    RowLayout{
                        anchors.fill:parent;anchors.margins:10;spacing:12
                        Text{text:Tr.t("Module editor");font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeLarge;color:Theme.textIn(QsWindow.window)}
                        ThemedComboBox{Layout.preferredWidth:250;model:root.entries;textRole:"name";currentIndex:root.entries.findIndex(i=>i.id===root.selected);onActivated:root.selected=root.entries[currentIndex].id}
                        Item{Layout.fillWidth:true}
                        Controls.TextField{visible:root.selected==="bar";id:presetName;Layout.preferredWidth:170;placeholderText:Tr.t("Preset name");font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeSmall;color:Theme.textIn(QsWindow.window);selectionColor:Theme.accentIn(QsWindow.window);selectedTextColor:Theme.accentTextIn(QsWindow.window);background:Rectangle{radius:Theme.radiusSmall;color:Theme.colourIn(QsWindow.window,"fieldBackground",Theme.islandSurface);border.width:1;border.color:presetName.activeFocus?Theme.accentIn(QsWindow.window):Theme.colourIn(QsWindow.window,"borderColor",Theme.border)} onTextEdited:stage.savedPreset=false}
                        PillButton{visible:root.selected==="bar";text:stage.savedPreset?Tr.t("Saved"):Tr.t("Save bar preset");onClicked:{const id=IslandPresetService.save(presetName.text.trim()||"My island");if(id){IslandPresetService.rememberActive(id);stage.savedPreset=true;savedNotice.restart()}}}
                        PillButton{text:Tr.t("Reset to defaults");onClicked:root.resetModule(root.selected)}
                        PillButton{text:Tr.t("Undo edits");onClicked:root.undo()}
                        PillButton{text:Tr.t("Done");active:true;onClicked:root.close()}
                    }
                }
                RowLayout{
                    Layout.fillWidth:true;Layout.fillHeight:true;spacing:16
                    Item{
                        id:previewArea
                        Layout.fillWidth:true;Layout.fillHeight:true
                        readonly property var nativeSize:catalogue.panelSizes[root.selected]||ModuleService.openSize(root.selected)
                        Rectangle{
                            id:frame
                            width:root.selected==="bar"?Math.max(280,previewArea.width-32):Math.max(200,previewArea.nativeSize.width||600)*(root.style.widthScale??100)/100
                            height:root.selected==="bar"?240:Math.max(120,previewArea.nativeSize.height||400)*(root.style.heightScale??100)/100
                            anchors.centerIn:parent
                            scale:Math.min(1,(previewArea.width-32)/width,(previewArea.height-160)/height)
                            radius:SettingsService.moduleRadius(root.selected,Theme.radiusLarge)
                            color:Theme.colourIn(QsWindow.window,"cardBackground",Theme.islandGround);border.color:Theme.colourIn(QsWindow.window,"borderColor",Theme.border);border.width:1
                            opacity:(root.style.opacity??100)/100
                            Loader{
                                id:previewContent
                                anchors.fill:parent;anchors.margins:root.selected==="bar"?0:root.style.padding??(root.selected==="launcher"?LauncherPresetService.style.padding:Theme.panelPadding)
                                enabled:false
                                asynchronous:true
                                sourceComponent:root.selected==="bar"?barPreview:(catalogue.panelComponents[root.selected]||detailPreview)
                                onLoaded:{root.selectedElement=null;root.previewItem=item;elementRefresh.restart()}
                            }
                            ModuleElementStyler{target:previewContent.item;moduleId:root.selected}
                            Rectangle{
                                id:selectionBorder
                                Component.onCompleted:root.selectionOutline=selectionBorder
                                Component.onDestruction:root.selectionOutline=null
                                visible:root.selectedElement!==null
                                color:"transparent";border.color:Theme.accentIn(QsWindow.window);border.width:2;radius:5;z:90
                                FrameAnimation{
                                    running:root.shown && root.selectedElement!==null
                                    onTriggered:{
                                        const item=root.selectedElement
                                        if(!item)return
                                        const corners=[item.mapToItem(frame,0,0),item.mapToItem(frame,item.width,0),item.mapToItem(frame,0,item.height),item.mapToItem(frame,item.width,item.height)]
                                        const xs=corners.map(p=>p.x),ys=corners.map(p=>p.y)
                                        selectionBorder.x=Math.min(...xs)-3;selectionBorder.y=Math.min(...ys)-3
                                        selectionBorder.width=Math.max(...xs)-Math.min(...xs)+6
                                        selectionBorder.height=Math.max(...ys)-Math.min(...ys)+6
                                    }
                                }
                            }
                            MouseArea{
                                id:editMouse
                                anchors.fill:parent;z:100;cursorShape:Qt.SizeAllCursor
                                property point start:Qt.point(0,0)
                                property real startX:0
                                property real startY:0
                                property real factor:1
                                function hit(node,point){
                                    const children=Array.from(node.children||[]).map((item,index)=>({item,index})).sort((a,b)=>b.item.z-a.item.z||b.index-a.index)
                                    for(const entry of children){
                                        const child=entry.item
                                        if(!child.visible)continue
                                        const local=child.mapFromItem(node,point)
                                        if(local.x<0||local.y<0||local.x>child.width||local.y>child.height)continue
                                        const found=hit(child,local)
                                        if(found)return found
                                    }
                                    return node.visible && ((node.objectName||"").startsWith("design:")||(node.objectName||"").startsWith("island-") && node.objectName!=="island-clock")?node:null
                                }
                                onPressed:mouse=>{
                                    const item=previewContent.item
                                    if(!item)return
                                    root.choose(hit(item,item.mapFromItem(editMouse,mouse.x,mouse.y)))
                                    start=Qt.point(mouse.x,mouse.y)
                                    factor=root.selected==="bar"?(item.previewScale??1):1
                                    startX=root.selectedChip?(root.selectedControl?root.controlStyle.x??0:root.chipStyle.offsetX??0):root.elementStyle.x??0
                                    startY=root.selectedChip?(root.selectedControl?root.controlStyle.y??0:root.chipStyle.offsetY??0):root.elementStyle.y??0
                                }
                                onPositionChanged:mouse=>{
                                    if(!pressed || (!root.selectedElement && !root.selectedChip))return
                                    const x=Math.round(startX+(mouse.x-start.x)/Math.max(0.05,factor))
                                    const y=Math.round(startY+(mouse.y-start.y)/Math.max(0.05,factor))
                                    if(root.selectedChip){root.setChip(root.selectedControl?"x":"offsetX",x);root.setChip(root.selectedControl?"y":"offsetY",y)}
                                    else{root.setElement("x",x);root.setElement("y",y)}
                                }
                                onReleased:elementRefresh.restart()
                            }
                        }
                        Flow{
                            visible:root.selected==="bar"
                            anchors.top:parent.top;anchors.left:parent.left;anchors.right:parent.right;spacing:7
                            Repeater{
                                model:root.targetElements
                                PillButton{
                                    required property var modelData
                                    text:typeof modelData.chipId==="string"?IslandChipService.names[modelData.chipId]+" chip":ModuleService.designLabel(modelData)
                                    active:root.selectedElement===modelData
                                    onClicked:root.choose(modelData)
                                }
                            }
                        }
                        Column{
                            visible:root.selected==="bar";anchors.bottom:parent.bottom;anchors.horizontalCenter:parent.horizontalCenter;spacing:10
                            Text{anchors.horizontalCenter:parent.horizontalCenter;text:Tr.t("Drag an icon onto the bar. Drag a chip or media button to position it.");font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeSmall;color:Theme.textIn(QsWindow.window)}
                            Row{
                                spacing:8
                                Repeater{
                                    model:IslandChipService.ids
                                    Rectangle{
                                        required property string modelData
                                        width:76;height:64;radius:12;color:Theme.colourIn(QsWindow.window,"cardBackground",Theme.islandGround);border.color:Theme.colourIn(QsWindow.window,"borderColor",Theme.border)
                                        Column{anchors.centerIn:parent;spacing:5
                                            Text{anchors.horizontalCenter:parent.horizontalCenter;text:({media:"󰎈",workspaces:"󰍹",internet:"󰖩",bluetooth:"󰂯",speaker:"󰕾",battery:"󰁹"})[modelData];font.family:Theme.fontMono;font.pixelSize:23;color:Theme.accentIn(QsWindow.window)}
                                            Text{anchors.horizontalCenter:parent.horizontalCenter;text:IslandChipService.names[modelData];font.family:Theme.fontIn(QsWindow.window);font.pixelSize:10;color:Theme.textIn(QsWindow.window)}
                                        }
                                        MouseArea{
                                            anchors.fill:parent;cursorShape:Qt.OpenHandCursor
                                            onPressed:mouse=>{stage.draggingIcon=modelData;stage.ghost=mapToItem(stage,mouse.x,mouse.y)}
                                            onPositionChanged:mouse=>{if(pressed)stage.ghost=mapToItem(stage,mouse.x,mouse.y)}
                                            onReleased:mouse=>{
                                                const p=mapToItem(frame,mouse.x,mouse.y)
                                                if(p.x>=0 && p.x<=frame.width && p.y>=0 && p.y<=frame.height){
                                                    root.addChip(modelData,p.x/frame.width)
                                                    elementRefresh.restart()
                                                }
                                                stage.draggingIcon=""
                                            }
                                            onCanceled:stage.draggingIcon=""
                                        }
                                    }
                                }
                            }
                        }
                        Text{visible:root.selected!=="bar";anchors.bottom:parent.bottom;anchors.horizontalCenter:parent.horizontalCenter;text:Tr.t("Click an element to select it, then drag or use the controls. Repeated rows share their style.");color:Theme.textIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeSmall}
                    }
                    Rectangle{
                        Layout.preferredWidth:Math.min(600,root.width*0.43);Layout.fillHeight:true;radius:Theme.radiusMedium;color:Theme.colourIn(QsWindow.window,"cardBackground",Theme.islandGround)
                        ColumnLayout{
                            anchors.fill:parent;anchors.margins:12
                            SegmentedControl{Layout.alignment:Qt.AlignHCenter;options:[{id:"presets",label:Tr.t("Presets")},{id:"elements",label:Tr.t("Elements")},{id:"style",label:Tr.t("Module style")},{id:"settings",label:Tr.t("Settings")}];current:root.controlsTab;onSelected:id=>root.controlsTab=id}
                            ModulePresets{visible:root.controlsTab==="presets";Layout.fillWidth:true;Layout.fillHeight:true;editor:root}
                            ModuleElementControls{visible:root.controlsTab==="elements";Layout.fillWidth:true;Layout.fillHeight:true;editor:root}
                            Flickable{
                                visible:root.controlsTab==="style";Layout.fillWidth:true;Layout.fillHeight:true;clip:true;contentHeight:styling.implicitHeight
                                ColumnLayout{
                                    id:styling;width:parent.width;spacing:8
                                    Text{visible:["volume","sound"].includes(root.selected);text:Tr.t("Volume controls");color:Theme.accentIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeMedium}
                                    SettingSlider{visible:["volume","sound"].includes(root.selected);label:Tr.t("Volume bar width");from:40;to:600;unit:" px";value:root.style.barWidth??220;onMoved:value=>root.setStyle("barWidth",Math.round(value))}
                                    SettingSlider{visible:["volume","sound"].includes(root.selected);label:Tr.t("Volume bar thickness");from:2;to:root.selected==="sound"?40:24;unit:" px";value:root.style.barHeight??(root.selected==="sound"?32:6);onMoved:value=>root.setStyle("barHeight",Math.round(value))}
                                    SettingSlider{visible:["volume","sound"].includes(root.selected);label:Tr.t("Volume text size");from:8;to:30;unit:" px";value:root.style.textSize??Theme.fontSizeSmall;onMoved:value=>root.setStyle("textSize",Math.round(value))}
                                    SettingSlider{visible:["volume","sound"].includes(root.selected);label:Tr.t("Volume icon size");from:10;to:40;unit:" px";value:root.style.iconSize??18;onMoved:value=>root.setStyle("iconSize",Math.round(value))}
                                    SettingSlider{visible:root.selected!=="bar";label:Tr.t("Width");from:60;to:160;unit:"%";value:root.style.widthScale??100;onMoved:value=>root.setStyle("widthScale",Math.round(value))}
                                    SettingSlider{visible:root.selected!=="bar";label:Tr.t("Height");from:60;to:160;unit:"%";value:root.style.heightScale??100;onMoved:value=>root.setStyle("heightScale",Math.round(value))}
                                    SettingSlider{visible:root.selected!=="bar";label:Tr.t("Padding");from:0;to:48;unit:" px";value:root.style.padding??Theme.panelPadding;onMoved:value=>root.setStyle("padding",Math.round(value))}
                                    SettingSlider{label:Tr.t("Rounding");from:0;to:64;unit:" px";value:SettingsService.moduleRadius(root.selected,Theme.radiusLarge);onMoved:value=>{const next=SettingsService.copy(SettingsService.moduleRounding)||{};next[root.selected]=Math.round(value);SettingsService.set("moduleRounding",next)}}
                                    SettingSlider{visible:root.selected!=="bar";label:Tr.t("Content opacity");from:30;to:100;unit:"%";value:root.style.opacity??100;onMoved:value=>root.setStyle("opacity",Math.round(value))}
                                    PillButton{text:Tr.t("Reset this module style");onClicked:{const next=SettingsService.copy(SettingsService.moduleAppearance)||{};delete next[root.selected];SettingsService.set("moduleAppearance",next);const rounds=SettingsService.copy(SettingsService.moduleRounding)||{};delete rounds[root.selected];SettingsService.set("moduleRounding",rounds)}}
                                }
                            }
                            Loader{
                                id:settingsLoader;visible:root.controlsTab==="settings";active:visible;Layout.fillWidth:true;Layout.fillHeight:true
                                source:"SettingsPanel.qml"
                                function route(){if(item)item.go(root.settingsSection(),root.settingsSection()==="island"?(root.selected==="bar"?"indicators":SettingsService.islandChipsEnabled?"chips":"indicators"):"")}
                                onLoaded:route()
                                Connections{target:root;function onSelectedChanged(){settingsLoader.route()}}
                            }
                        }
                    }
                }
            }
            Rectangle{visible:stage.draggingIcon!=="";x:stage.ghost.x-24;y:stage.ghost.y-24;width:48;height:48;radius:24;color:Theme.accentIn(QsWindow.window);opacity:0.9;z:1000
                Text{anchors.centerIn:parent;text:({media:"󰎈",workspaces:"󰍹",internet:"󰖩",bluetooth:"󰂯",speaker:"󰕾",battery:"󰁹"})[stage.draggingIcon]||"";font.family:Theme.fontMono;font.pixelSize:26;color:Theme.accentTextIn(QsWindow.window)}
            }
            Component{id:barPreview;IslandPresetPreview{values:IslandPresetService.capture();editMode:true}}
            Component{id:detailPreview;DetailFace{moduleId:root.selected}}
        }
    }
}
