import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../services"
import "../../components"

ColumnLayout {
    id: root
    objectName: "design:DocumentLibraryPanel"
    property bool fullscreenMode: false
    property string backend: Quickshell.shellPath("scripts/document_library.py")
    property string folder: "all"
    property string filter: ""
    property string order: "recent"
    property string typeFilter:"all"
    property var hoveredDocument:null
    readonly property color navigationAccent:Qt.tint(Theme.moduleColour("documents","accent",Theme.accent),Qt.rgba(1,1,1,.3))
    property var documents: []
    property var roots: []
    property var previews: ({})
    property var viewport: ({})
    property var previewQueue: []
    property string renderingPath: ""
    property string message: ""
    property bool scanned: false
    property bool ready: false
    property bool dying: false
    property bool renderStopping: false
    property bool keyboardSelection: true
    property bool verticalMove:false
    property int moveDirection:1
    readonly property string selectionMotion: SettingsService.documentLibraryMotion || "slide"
    readonly property int selectionDuration: Math.max(0, SettingsService.documentLibraryMotionDuration ?? 180)
    readonly property int visibleRows:Math.max(1,Math.min(6,SettingsService.documentLibraryRows))
    readonly property int gridColumns:Math.max(1,Math.round(grid.width/grid.cellWidth))
    readonly property int motionDuration:root.selectionMotion === "none" ? 0 : root.selectionDuration
    signal closed()
    signal documentRequested(string path)
    signal fullscreenRequested()
    spacing: 12
    readonly property var typeChoices:[
        {id:"all",name:"All types",color:Theme.moduleColour("documents","foreground",Theme.text)},
        {id:"word",name:"Word",color:"#8db6ff"},
        {id:"pdf",name:"PDF",color:"#ff969c"},
        {id:"slides",name:"Slides",color:"#ffc08d"},
        {id:"sheets",name:"Sheets",color:"#81d8b2"},
        {id:"text",name:"Text",color:"#c3adf5"}
    ]
    function fileType(document:var):var {
        const extension=(document?.extension||"").toLowerCase()
        if(extension==="pdf")return {id:"pdf",label:"PDF document",mark:"PDF",color:"#ff969c",app:"PDFCraft"}
        if(["pptx","deckcraft"].includes(extension))return {id:"slides",label:"Presentation",mark:"P",color:"#ffc08d",app:"DeckCraft"}
        if(extension==="xlsx")return {id:"sheets",label:"Spreadsheet",mark:"X",color:"#81d8b2",app:"GridCraft"}
        if(["docx","docm","dotx","dotm","doc","odt","rtf"].includes(extension))return {id:"word",label:"Word document",mark:"W",color:"#8db6ff",app:"WordCraft"}
        return {id:"text",label:extension==="md"||extension==="markdown"?"Markdown":"Text document",mark:"T",color:"#c3adf5",app:"WordCraft"}
    }
    readonly property var matchingDocuments:documents.filter(d=>(root.folder==="all"||d.folder===root.folder)
        && (d.name+" "+d.relative).toLowerCase().includes(root.filter.trim().toLowerCase()))
    readonly property var rows:matchingDocuments.filter(d=>root.typeFilter==="all"||root.fileType(d).id===root.typeFilter)
        .sort((a,b)=>root.order==="name"?a.name.localeCompare(b.name):root.order==="type"?a.extension.localeCompare(b.extension)||a.name.localeCompare(b.name):b.mtime-a.mtime)
    readonly property var typeCounts:{
        const counts={all:root.matchingDocuments.length,word:0,pdf:0,slides:0,sheets:0,text:0}
        for(const document of root.matchingDocuments)counts[root.fileType(document).id]++
        return counts
    }
    readonly property var folders:[{id:"all",name:Tr.t("All folders"),count:documents.length}].concat(roots)
    readonly property var selectedDocument:root.rows[grid.currentIndex]||null
    readonly property var inspectedDocument:root.hoveredDocument||root.selectedDocument
    function resetPosition():void {root.hoveredDocument=null;root.keyboardSelection=true;if(grid){scrollMotion.stop();grid.currentIndex=0;grid.contentY=0}}
    function locationLabel(document:var):string {
        const parts=(document?.relative||"").split("/");parts.pop()
        return parts.length?parts.slice(-2).join("/"):root.roots.find(r=>r.id===document?.folder)?.name||document?.folder||""
    }
    function changedLabel(document:var):string {return document?Qt.formatDateTime(new Date(document.mtime*1000),"dd MMM · HH:mm"):""}
    function clearFilters():void {root.folder="all";root.typeFilter="all";root.filter="";search.text="";root.resetPosition()}
    onTypeFilterChanged:root.resetPosition()
    onFolderChanged:root.resetPosition()

    function refresh(): void {
        if (!root.visible || scan.running) return
        root.message = ""
        root.stopRenderer()
        root.previews = ({})
        root.previewQueue = Object.keys(root.viewport)
        scan.running = true
    }
    function stopRenderer(): void {
        if(renderer.running) {
            renderer.cancelled=true
            root.renderStopping=true
            renderer.running=false
        } else root.renderingPath=""
    }
    function pause(): void {
        scan.running = false
        root.stopRenderer()
        root.previewQueue = []
        root.viewport = ({})
    }
    function watchPreview(path: string, wanted: bool): void {
        const next = Object.assign({}, root.viewport)
        if (wanted) next[path] = true
        else delete next[path]
        root.viewport = next
        root.previewQueue = root.previewQueue.filter(p => next[p])
        if (wanted && root.previews[path] === undefined && root.renderingPath !== path && !root.previewQueue.includes(path))
            root.previewQueue = root.previewQueue.concat([path])
        Qt.callLater(root.renderNext)
    }
    function renderNext(): void {
        if (root.dying || !root.visible || renderer.running || root.renderStopping || scan.running) return
        const pending = root.previewQueue.filter(path => root.viewport[path] && root.previews[path] === undefined)
        if (!pending.length) { root.previewQueue = []; return }
        root.renderingPath = pending[0]
        renderer.jobPath=root.renderingPath
        renderer.cancelled=false
        root.previewQueue = pending.slice(1)
        renderer.command = [root.backend, "preview", root.renderingPath]
        renderer.running = true
    }
    function moveSelection(step: int): void {
        if(!grid.count) return
        root.keyboardSelection=true
        root.verticalMove=Math.abs(step)>=root.gridColumns
        root.moveDirection=step<0?-1:1
        grid.currentIndex=Math.max(0,Math.min(grid.count-1,Math.max(0,grid.currentIndex)+step))
        root.revealSelection()
    }
    function revealSelection():void {
        const top=Math.floor(grid.currentIndex/root.gridColumns)*grid.cellHeight
        const bottom=top+grid.cellHeight
        let destination=grid.contentY
        if(top<destination)destination=top
        else if(bottom>destination+grid.height)destination=bottom-grid.height
        destination=Math.max(0,Math.min(Math.max(0,grid.contentHeight-grid.height),destination))
        scrollMotion.stop()
        if(Math.abs(grid.contentY-destination)<.5){grid.contentY=destination;return}
        if(root.motionDuration===0)grid.contentY=destination
        else {scrollMotion.from=grid.contentY;scrollMotion.to=destination;scrollMotion.restart()}
    }
    function openCurrent(): void {
        if(grid.currentIndex >= 0 && root.rows[grid.currentIndex])root.documentRequested(root.rows[grid.currentIndex].path)
    }
    function navigate(key: int): bool {
        const columns=Math.max(1,Math.round(grid.width/grid.cellWidth))
        if(key===Qt.Key_Left)root.moveSelection(-1)
        else if(key===Qt.Key_Right)root.moveSelection(1)
        else if(key===Qt.Key_Up)root.moveSelection(-columns)
        else if(key===Qt.Key_Down)root.moveSelection(columns)
        else if(key===Qt.Key_PageUp)root.moveSelection(-columns*Math.max(1,Math.floor(grid.height/grid.cellHeight)))
        else if(key===Qt.Key_PageDown)root.moveSelection(columns*Math.max(1,Math.floor(grid.height/grid.cellHeight)))
        else if(key===Qt.Key_Home){grid.currentIndex=0;root.moveSelection(0)}
        else if(key===Qt.Key_End){grid.currentIndex=grid.count-1;root.moveSelection(0)}
        else if(key===Qt.Key_Return||key===Qt.Key_Enter)root.openCurrent()
        else return false
        return true
    }
    function navigationStatus():var {return {rows:root.visibleRows,columns:root.gridColumns,count:grid.count,index:grid.currentIndex,selectionX:selection.x,selectionY:selection.y,scrollY:grid.contentY,cellHeight:grid.cellHeight,cellWidth:grid.cellWidth,motion:root.selectionMotion,duration:root.motionDuration,scrolling:scrollMotion.running}}
    function browse(direction:string):void {const keys={up:Qt.Key_Up,down:Qt.Key_Down,left:Qt.Key_Left,right:Qt.Key_Right};if(keys[direction]){grid.forceActiveFocus();root.navigate(keys[direction])}}
    function sizeLabel(bytes: real): string {
        return bytes >= 1048576 ? (bytes/1048576).toFixed(1) + " MB" : Math.max(1, Math.round(bytes/1024)) + " KB"
    }
    onVisibleChanged: if(root.ready) { if(visible) { if(!scanned) refresh();Qt.callLater(root.renderNext) } else pause() }
    Component.onCompleted: { root.ready=true;root.refresh();Qt.callLater(()=>grid.forceActiveFocus()) }
    Component.onDestruction: { root.dying=true;root.pause() }
    Keys.onEscapePressed: event => { event.accepted=true;root.closed() }

    Process {
        id: scan
        command: [root.backend, "scan"]
        stdout: StdioCollector {
            onStreamFinished: {
                if(root.dying || !text.trim()) return
                try {
                    const result=JSON.parse(text)
                    root.documents=result.documents || []
                    root.roots=result.roots || []
                    root.scanned=true
                    Qt.callLater(root.renderNext)
                    root.message=result.truncated ? Tr.t("Showing the most recent 3,000 documents. Narrow your search by folder.")
                        : (result.errors || []).length ? Tr.t("Some folders could not be read. Available documents are shown.") : ""
                } catch(error) { root.message=Tr.t("Could not read the document library.") }
            }
        }
        onExited: code => {
            if(code!==0 && root.visible && !root.dying)root.message=Tr.t("Could not scan your folders. Try Refresh.")
            if(!root.dying)Qt.callLater(root.renderNext)
        }
    }
    Process {
        id: renderer
        property string jobPath:""
        property bool cancelled:false
        stdout: StdioCollector {
            onStreamFinished: {
                if(root.dying || renderer.cancelled || !root.visible || !renderer.jobPath || !text.trim()) return
                try {
                    const result=JSON.parse(text), next=Object.assign({},root.previews)
                    next[renderer.jobPath]={path:result.path || "", error:result.error || ""}
                    root.previews=next
                } catch(error) {
                    const next=Object.assign({},root.previews);next[renderer.jobPath]={path:"",error:"Preview unavailable"};root.previews=next
                }
            }
        }
        onExited: code => {
            if(root.dying) return
            if(code!==0 && !renderer.cancelled && root.visible && renderer.jobPath) {
                const next=Object.assign({},root.previews);next[renderer.jobPath]={path:"",error:"Preview unavailable"};root.previews=next
            }
            root.renderingPath=""
            Qt.callLater(function(){root.renderStopping=false;root.renderNext()})
        }
    }

    RowLayout {
        Layout.fillWidth:true;spacing:10
        Text {text:Tr.t("Documents");font.family:Theme.fontFamily;font.pixelSize:20;font.weight:Font.DemiBold;color:Theme.moduleColour("documents","foreground",Theme.text)}
        Text {text:scan.running?Tr.t("Scanning…"):String(root.rows.length);font.family:Theme.fontFamily;font.pixelSize:12;color:Theme.moduleColour("documents","muted",Theme.textMuted)}
        Item {Layout.fillWidth:true}
        IconButton {icon:"󰇙";onClicked:viewOptions.open()
            HoverHandler {id:optionsHelp}
            Controls.ToolTip.visible:optionsHelp.hovered;Controls.ToolTip.text:Tr.t("View options");Controls.ToolTip.delay:500
        }
        IconButton {icon:"󰅖";onClicked:root.closed()}
    }
    RowLayout {
        Layout.fillWidth:true;spacing:8
        Rectangle {
            Layout.fillWidth:true;implicitHeight:36;radius:10;color:Theme.islandSurface;border.width:1;border.color:search.activeFocus?root.navigationAccent:Theme.border
            Text {anchors.left:parent.left;anchors.leftMargin:11;anchors.verticalCenter:parent.verticalCenter;text:"󰍉";font.family:Theme.fontMono;font.pixelSize:14;color:Theme.moduleColour("documents","muted",Theme.textMuted)}
            TextInput {
                id:search
                anchors.fill:parent;anchors.leftMargin:34;anchors.rightMargin:12
                verticalAlignment:TextInput.AlignVCenter;selectByMouse:true;clip:true
                font.family:Theme.fontFamily;font.pixelSize:13;color:Theme.moduleColour("documents","foreground",Theme.text);selectionColor:Theme.moduleColour("documents","accent",Theme.accent);selectedTextColor:Theme.accentText
                onTextEdited:{root.filter=text;root.resetPosition()}
                Keys.onDownPressed:event=>{event.accepted=true;grid.forceActiveFocus();root.moveSelection(0)}
                Keys.onUpPressed:event=>{event.accepted=true;grid.forceActiveFocus();root.moveSelection(0)}
                Keys.onReturnPressed:root.openCurrent()
                Keys.onEnterPressed:root.openCurrent()
                Keys.onEscapePressed:event=>{event.accepted=true;root.closed()}
                Text {anchors.verticalCenter:parent.verticalCenter;visible:search.text==="";text:Tr.t("Search documents…");font:search.font;color:Theme.moduleColour("documents","muted",Theme.textMuted)}
            }
        }
        ThemedComboBox {
            Layout.preferredWidth:Math.min(160,root.width*.22);model:root.folders;textRole:"name";focusPolicy:Qt.NoFocus
            currentIndex:Math.max(0,model.findIndex(e=>e.id===root.folder))
            onActivated:{root.folder=model[currentIndex].id;Qt.callLater(()=>grid.forceActiveFocus())}
        }
        ThemedComboBox {
            Layout.preferredWidth:116;model:root.typeChoices;textRole:"name";focusPolicy:Qt.NoFocus
            currentIndex:Math.max(0,model.findIndex(e=>e.id===root.typeFilter))
            onActivated:{root.typeFilter=model[currentIndex].id;Qt.callLater(()=>grid.forceActiveFocus())}
        }
    }
    Item {
        Layout.fillWidth:true;Layout.fillHeight:true
        GridView {
            id:grid
            anchors.fill:parent;clip:true;cacheBuffer:0;reuseItems:true
            cellWidth:width/Math.max(1,Math.floor(width/(root.fullscreenMode?224:194)))
            cellHeight:Math.max(180,Math.floor(height/root.visibleRows))
            highlightFollowsCurrentItem:false
            keyNavigationEnabled:false
            Item {
                id:selection
                parent:grid.contentItem
                z:20
                x:(Math.max(0,grid.currentIndex)%root.gridColumns)*grid.cellWidth
                y:Math.floor(Math.max(0,grid.currentIndex)/root.gridColumns)*grid.cellHeight
                width:grid.cellWidth;height:grid.cellHeight
                visible:root.keyboardSelection && grid.count>0
                property real reveal:1
                property real settledScale:1
                Behavior on x {NumberAnimation {duration:root.motionDuration;easing.type:root.selectionMotion==="bounce"?Easing.OutBack:Easing.OutCubic;easing.overshoot:.75}}
                Behavior on y {NumberAnimation {duration:root.motionDuration;easing.type:root.selectionMotion==="bounce"?Easing.OutBack:Easing.OutCubic;easing.overshoot:.75}}
                function replay():void {
                    fade.stop();settle.stop();reveal=1;settledScale=1
                    if(root.selectionMotion==="fade"){reveal=0;fade.start()}
                    else if(root.selectionMotion==="bounce"){settledScale=.965;settle.start()}
                }
                Connections {target:grid;function onCurrentIndexChanged(){selection.replay()}}
                Rectangle {anchors.fill:parent;anchors.margins:5;radius:14;color:"transparent";border.width:2;border.color:root.navigationAccent;opacity:selection.reveal;scale:selection.settledScale}
                NumberAnimation {id:fade;target:selection;property:"reveal";from:0;to:1;duration:root.motionDuration;easing.type:Easing.OutCubic}
                NumberAnimation {id:settle;target:selection;property:"settledScale";from:.965;to:1;duration:root.motionDuration;easing.type:Easing.OutBack;easing.overshoot:.75}
            }
            keyNavigationWraps:false
            activeFocusOnTab:true
            onCountChanged:currentIndex=count?Math.min(Math.max(0,currentIndex),count-1):-1
            Keys.onPressed:event=>{
                if(root.navigate(event.key)){event.accepted=true;return}
                if(!(event.modifiers&(Qt.ControlModifier|Qt.AltModifier|Qt.MetaModifier)) && event.text && event.text.length===1 && event.text.charCodeAt(0)>=32){
                    search.forceActiveFocus();search.text+=event.text;root.filter=search.text;root.resetPosition();event.accepted=true
                }
            }
            model:ScriptModel { values:root.rows }
            boundsBehavior:Flickable.StopAtBounds
            Controls.ScrollBar.vertical:Controls.ScrollBar {}
            NumberAnimation {id:scrollMotion;target:grid;property:"contentY";duration:root.motionDuration;easing.type:Easing.OutCubic}
            onMovementStarted:scrollMotion.stop()
            onCellHeightChanged:Qt.callLater(()=>{scrollMotion.stop();grid.contentY=0;root.revealSelection()})
            delegate:Item {
                id:tile
                required property var modelData
                required property int index
                readonly property bool selected:root.keyboardSelection && grid.currentIndex===index
                readonly property var kind:root.fileType(tile.modelData)
                width:grid.cellWidth;height:grid.cellHeight
                property string watched:""
                property bool pooled:false
                readonly property bool inViewport:root.visible&&!pooled&&y+height>grid.contentY&&y<grid.contentY+grid.height
                readonly property var preview:root.previews[modelData.path]
                function syncWatch():void {
                    if(watched && (watched!==modelData.path || !inViewport))root.watchPreview(watched,false)
                    watched=inViewport?modelData.path:""
                    if(watched)root.watchPreview(watched,true)
                }
                onInViewportChanged:syncWatch()
                onModelDataChanged:syncWatch()
                Component.onCompleted:syncWatch()
                Component.onDestruction:if(watched&&!root.dying)root.watchPreview(watched,false)
                GridView.onPooled:pooled=true
                GridView.onReused:pooled=false
                Rectangle {
                    anchors.fill:parent;anchors.margins:6;radius:16
                    color:mouse.containsMouse?Qt.tint(Theme.islandSurface,Qt.alpha(tile.kind.color,.045)):Theme.islandSurface
                    border.width:1;border.color:mouse.containsMouse?Qt.alpha(tile.kind.color,.65):Theme.border
                    ColumnLayout {
                        anchors.fill:parent;anchors.margins:tile.height<150?7:11;spacing:tile.height<150?4:8
                        Rectangle {
                            visible:tile.height>=120
                            Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:0;radius:8;color:"#f2f3f5";clip:true
                            Image {
                                anchors.fill:parent;anchors.margins:4
                                source:tile.inViewport&&tile.preview?.path?"file://"+tile.preview.path:""
                                asynchronous:true;cache:false;fillMode:Image.PreserveAspectFit
                                sourceSize.width:256;sourceSize.height:360
                                visible:status===Image.Ready
                            }
                            Text {
                                anchors.centerIn:parent;visible:!tile.preview?.path
                                text:tile.preview?.error?Tr.t("No preview"):tile.modelData.extension.toUpperCase()
                                font.family:Theme.fontFamily;font.pixelSize:12;font.weight:Font.DemiBold;color:"#647085"
                            }
                            Rectangle {
                                anchors.left:parent.left;anchors.top:parent.top;anchors.margins:6
                                width:extensionLabel.implicitWidth+12;height:20;radius:5
                                color:Qt.tint("#e8edf2",Qt.alpha(tile.kind.color,.3))
                                Text {id:extensionLabel;anchors.centerIn:parent;text:tile.modelData.extension.toUpperCase();font.family:Theme.fontFamily;font.pixelSize:9;font.weight:Font.DemiBold;color:"#354252"}
                            }
                        }
                        Text {Layout.fillWidth:true;Layout.preferredHeight:tile.height<120?28:32;text:tile.modelData.name;textFormat:Text.PlainText;wrapMode:Text.WrapAnywhere;maximumLineCount:2;elide:Text.ElideRight;font.family:Theme.fontFamily;font.pixelSize:12;font.weight:Font.DemiBold;color:Theme.moduleColour("documents","foreground",Theme.text)}
                        RowLayout {Layout.fillWidth:true;spacing:4
                            Text {Layout.fillWidth:true;text:root.locationLabel(tile.modelData);elide:Text.ElideRight;color:Theme.moduleColour("documents","muted",Theme.textMuted);font.family:Theme.fontFamily;font.pixelSize:10}
                        }
                    }
                    Controls.ToolTip.visible:mouse.containsMouse
                    Controls.ToolTip.text:tile.modelData.relative+"\n"+Tr.t("Open in ")+tile.kind.app+" · "+root.changedLabel(tile.modelData)
                    Controls.ToolTip.delay:450
                    MouseArea {
                        id:mouse;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor
                        onEntered:root.hoveredDocument=tile.modelData
                        onExited:if(root.hoveredDocument?.path===tile.modelData.path)root.hoveredDocument=null
                        onClicked:{grid.currentIndex=tile.index;root.documentRequested(tile.modelData.path)}
                    }
                }
            }
        }
        Column {
            anchors.centerIn:parent;spacing:10;visible:root.rows.length===0
            Text {anchors.horizontalCenter:parent.horizontalCenter;text:scan.running?"󰑐":"󰈙";font.family:Theme.fontMono;font.pixelSize:36;color:Theme.moduleColour("documents","accent",Theme.accent)}
            Text {anchors.horizontalCenter:parent.horizontalCenter;text:scan.running?Tr.t("Finding your files…"):Tr.t("No files match these filters");font.family:Theme.fontFamily;font.pixelSize:14;color:Theme.moduleColour("documents","foreground",Theme.text)}
            PillButton {anchors.horizontalCenter:parent.horizontalCenter;visible:!scan.running&&(root.filter!==""||root.typeFilter!=="all"||root.folder!=="all");text:Tr.t("Clear filters");onClicked:root.clearFilters()}
        }
    }
    RowLayout {
        Layout.fillWidth:true;spacing:12
        Text {Layout.fillWidth:true;text:root.selectedDocument?.relative||Tr.t("Documents · Downloads · Desktop · Projects");elide:Text.ElideMiddle;font.family:Theme.fontFamily;font.pixelSize:10;color:Theme.moduleColour("documents","muted",Theme.textMuted)}
        Text {text:Tr.t("Arrows browse · Enter opens · / searches");font.family:Theme.fontFamily;font.pixelSize:10;color:Theme.moduleColour("documents","muted",Theme.textMuted)}
        Text {visible:grid.count>0;text:(Math.max(0,grid.currentIndex)+1)+" / "+grid.count;font.family:Theme.fontFamily;font.pixelSize:10;color:Theme.moduleColour("documents","muted",Theme.textMuted)}
    }
    Text {Layout.fillWidth:true;visible:root.message!=="";text:root.message;wrapMode:Text.WordWrap;font.family:Theme.fontFamily;font.pixelSize:10;color:Theme.moduleColour("documents","muted",Theme.textMuted)}
    Shortcut {sequence:"Ctrl+F";context:Qt.WindowShortcut;enabled:root.visible;onActivated:{search.forceActiveFocus();search.selectAll()}}
    Shortcut {sequence:"/";context:Qt.WindowShortcut;enabled:root.visible&&!search.activeFocus;onActivated:search.forceActiveFocus()}
    Shortcut {sequence:"Ctrl+R";context:Qt.WindowShortcut;enabled:root.visible;onActivated:root.refresh()}
    Controls.Popup {
        id:viewOptions
        parent:root;x:Math.max(0,root.width-width);y:36;width:280;padding:16;focus:true
        closePolicy:Controls.Popup.CloseOnEscape|Controls.Popup.CloseOnPressOutside
        onClosed:if(root.visible&&!root.dying)Qt.callLater(()=>grid.forceActiveFocus())
        background:Rectangle {radius:14;color:Theme.islandSurface;border.width:1;border.color:Theme.border}
        contentItem:ColumnLayout {
            spacing:12
            Text {text:Tr.t("View options");font.family:Theme.fontFamily;font.pixelSize:14;font.weight:Font.DemiBold;color:Theme.moduleColour("documents","foreground",Theme.text)}
            Text {text:Tr.t("Sort by");font.family:Theme.fontFamily;font.pixelSize:11;color:Theme.moduleColour("documents","muted",Theme.textMuted)}
            ThemedComboBox {Layout.fillWidth:true;model:[{id:"recent",name:Tr.t("Newest first")},{id:"name",name:Tr.t("Name A–Z")},{id:"type",name:Tr.t("File type")}];textRole:"name";currentIndex:Math.max(0,model.findIndex(e=>e.id===root.order));onActivated:{root.order=model[currentIndex].id;root.resetPosition()}}
            Text {text:Tr.t("Visible rows");font.family:Theme.fontFamily;font.pixelSize:11;color:Theme.moduleColour("documents","muted",Theme.textMuted)}
            ThemedComboBox {Layout.fillWidth:true;model:[1,2,3,4,5,6];displayText:String(root.visibleRows);currentIndex:root.visibleRows-1;onActivated:{SettingsService.set("documentLibraryRows",model[currentIndex]);Qt.callLater(root.revealSelection)}}
            Text {text:Tr.t("Selection animation");font.family:Theme.fontFamily;font.pixelSize:11;color:Theme.moduleColour("documents","muted",Theme.textMuted)}
            ThemedComboBox {Layout.fillWidth:true;model:[{id:"slide",name:Tr.t("Smooth slide")},{id:"fade",name:Tr.t("Fade")},{id:"bounce",name:Tr.t("Soft bounce")},{id:"none",name:Tr.t("Instant")}];textRole:"name";currentIndex:Math.max(0,model.findIndex(e=>e.id===root.selectionMotion));onActivated:SettingsService.set("documentLibraryMotion",model[currentIndex].id)}
            ThemedComboBox {Layout.fillWidth:true;model:[60,120,180,260,360,500];displayText:root.selectionDuration+" ms";currentIndex:Math.max(0,model.indexOf(root.selectionDuration));enabled:root.selectionMotion!=="none";onActivated:SettingsService.set("documentLibraryMotionDuration",model[currentIndex])}
            RowLayout {Layout.fillWidth:true
                PillButton {text:Tr.t("Refresh");enabled:!scan.running;onClicked:{viewOptions.close();root.refresh()}}
                PillButton {visible:!root.fullscreenMode;text:Tr.t("Full screen");onClicked:{viewOptions.close();root.fullscreenRequested()}}
            }
        }
    }
}
