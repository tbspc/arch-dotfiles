import QtQuick
import Quickshell
import "../../theme"
import "../../services"
import "../../components"

FocusScope {
    id:root
    signal closed()
    signal panelRequested(string panel)
    property string page:"wallpaper"
    property string shown:root.page
    property bool preview:false
    property bool compact:false
    property string query:""
    readonly property bool onPalette:shown==="palette"
    readonly property bool onAnimated:shown==="animated"
    readonly property var pages:["animated","wallpaper","palette"]
    readonly property var entries: {
        const list=root.onPalette?ThemeService.availableThemes:root.onAnimated?ThemeService.browsableAnimated:ThemeService.browsableWallpapers
        const q=root.query.trim().toLowerCase()
        return q?list.filter(entry=>(entry.name||"").toLowerCase().includes(q)):list
    }
    readonly property var selected:root.entries[strip.current]||null
    function settle():void {
        const n=root.entries.findIndex(entry=>root.onPalette?entry.id===ThemeService.activeId:entry.path===WallpaperService.chosen)
        strip.goTo(Math.max(0,n))
    }
    function turn(delta:int):void {
        const i=root.pages.indexOf(root.shown)+delta
        if(i<0||i>=root.pages.length)return
        root.shown=root.pages[i];search.text=""
        if(root.shown!=="animated")root.panelRequested(root.onPalette?"palette":"appearance")
        root.settle()
    }
    function apply():void {
        if(root.preview||!root.selected)return
        if(root.onPalette)ThemeService.setTheme(root.selected.id)
        else WallpaperService.apply(root.selected.path,!ThemeService.wallpaperFilterActive)
    }
    function browse(direction:string):void {
        if(direction==="left")strip.step(-1)
        else if(direction==="right")strip.step(1)
        else if(direction==="up")root.turn(-1)
        else if(direction==="down")root.turn(1)
        else if(direction==="apply")root.apply()
    }
    function key(event):void {
        if(event.key===Qt.Key_Left)strip.step(-1)
        else if(event.key===Qt.Key_Right)strip.step(1)
        else if(event.key===Qt.Key_Up)root.turn(-1)
        else if(event.key===Qt.Key_Down)root.turn(1)
        else if(event.key===Qt.Key_Return||event.key===Qt.Key_Enter)root.apply()
        else if(event.key===Qt.Key_Escape)root.closed()
        else if(event.key===Qt.Key_F5)WallpaperService.scan()
        else return
        event.accepted=true
    }
    function navigationStatus():var {return {design:root.compact?"gallery":"reference",page:root.shown,count:root.entries.length,index:strip.current,query:root.query,selected:root.selected?.id||root.selected?.path||"",searchIcon:true,visibleCards:root.compact?Object.values(strip.tileObjects).filter(tile=>tile&&tile.visible&&tile.opacity>.01).length:0}}
    function swatches(entry:var):var {return ThemeService.previewSwatches(entry)}

    onPageChanged:{root.shown=root.page;search.text="";root.settle()}
    onEntriesChanged:Qt.callLater(root.settle)
    onVisibleChanged:if(visible&&!root.preview){WallpaperService.scan();Qt.callLater(()=>root.compact?root.forceActiveFocus():search.forceActiveFocus())}
    Component.onCompleted:{root.settle();if(!preview){WallpaperService.scan();if(root.compact)root.forceActiveFocus();else search.forceActiveFocus()}}
    Keys.onPressed:event=>root.key(event)

    Item {
        x:0;y:0;width:parent.width;height:28;visible:!root.compact
        SearchMagnifier {x:1;y:6;width:14;height:14;ink:"#85837c"}
        TextInput {
            id:search
            x:27;y:0;width:parent.width-82;height:28
            verticalAlignment:TextInput.AlignVCenter
            font.family:Theme.fontFamily;font.pixelSize:14;color:Theme.text
            selectionColor:Theme.accent;selectedTextColor:Theme.accentText
            selectByMouse:true;enabled:!root.preview
            onTextChanged:{root.query=text;strip.goTo(0)}
            Keys.priority:Keys.BeforeItem
            Keys.onPressed:event=>root.key(event)
            Text {
                anchors.fill:parent;verticalAlignment:Text.AlignVCenter
                visible:!search.text&&!search.preeditText
                text:root.onPalette?Tr.t("Search themes..."):root.onAnimated?Tr.t("Search animated wallpapers..."):Tr.t("Search wallpapers...")
                font:search.font;color:"#85837c"
            }
        }
        Text {
            anchors.right:parent.right;y:7
            text:root.entries.length?`${strip.current+1}/${root.entries.length}`:"0/0"
            color:"#85837c";font.family:Theme.fontFamily;font.pixelSize:11
        }
    }
    Item {
        visible:root.compact;x:0;y:0;width:parent.width;height:20
        Text {y:3;text:root.onPalette?Tr.t("Themes"):root.onAnimated?Tr.t("Animated wallpapers"):Tr.t("Wallpaper");font.family:Theme.fontFamily;font.pixelSize:18;color:Theme.text}
        Text {anchors.right:parent.right;y:6;text:ThemeService.paletteFor(ThemeService.activeId)?.name||"";font.family:Theme.fontFamily;font.pixelSize:12;color:"#85837c"}
    }
    Carousel {
        id:strip
        x:(parent.width-width)/2;y:root.compact?37:46;width:root.compact?Math.min(parent.width,5*tileWidth+4*gap+tileWidth*.1):parent.width;height:root.compact?137:112
        model:root.entries;virtualized:true
        tileWidth:root.compact?Math.max(1,Math.min(170,Math.floor((parent.width-72)/5.1))):186;tileHeight:root.compact?tileWidth*.6:96;centreScale:1;gap:root.compact?18:10;reach:3
        // Keep five cards in view even at either end of the collection.
        position:root.compact?(count>=5?Math.max(2,Math.min(count-3,current)):Math.max(0,(count-1)/2)):current
        onActivated:root.apply()
        delegate:CarouselTile {
            id:tile
            y:(strip.height-height)/2-(root.compact?0:8*Math.max(0,1-Math.abs(distance)))
            // Show five cards, with a small emphasis on the selected wallpaper.
            scale:root.compact?(centred?1.1:1):strip.scaleOf(distance)
            opacity:root.compact?Math.max(0,Math.min(1,3-Math.abs(distance)))*(tile.centred?1:Math.max(.7,1-.13*Math.abs(distance))):1
            visible:Math.abs(distance)<strip.reach
            readonly property bool applied:root.onPalette?modelData.id===ThemeService.activeId:modelData.path===WallpaperService.chosen
            AntialiasedPreview {
                anchors.fill:parent;radius:root.compact?15:13
                color:tile.centred?Qt.tint("#050a09",Qt.alpha(Theme.accent,.035)):"#121218"
                borderColor:tile.centred?Theme.accent:"#202027";borderWidth:tile.centred?2:1
                Image {
                    anchors.fill:parent
                    visible:!root.onPalette
                    source:root.onPalette?"":"file://"+(tile.modelData.poster||tile.modelData.path)
                    sourceSize:root.compact?Qt.size(256,160):Qt.size(374,192);fillMode:Image.PreserveAspectCrop;asynchronous:true;cache:true
                }
                Rectangle {visible:!root.onPalette&&!root.compact;anchors.bottom:parent.bottom;width:parent.width;height:27;color:"#b3000000"}
                Row {
                    visible:root.onPalette
                    anchors.horizontalCenter:parent.horizontalCenter;y:root.compact?32:33;spacing:root.compact?4:5
                    Repeater {model:root.onPalette?root.swatches(tile.modelData):[]
                        Rectangle {required property var modelData;width:root.compact?12:14;height:width;radius:width/2;color:modelData}
                    }
                }
                Text {
                    visible:!root.compact||root.onPalette
                    x:8;width:parent.width-16;anchors.bottom:parent.bottom;anchors.bottomMargin:root.compact?6:9
                    horizontalAlignment:Text.AlignHCenter;elide:Text.ElideRight
                    text:tile.modelData.name||""
                    color:tile.centred?Theme.text:"#9996a8";font.family:Theme.fontFamily;font.pixelSize:12
                }
                Rectangle {visible:tile.applied;x:parent.width-width-(root.compact?7:8);y:root.compact?7:8;width:root.compact?4.5:6;height:width;radius:width/2;color:Theme.accent}
            }
        }
    }
    Text {
        anchors.centerIn:strip;width:parent.width-48;visible:root.entries.length===0
        text:root.query?Tr.t("No results"):Tr.t("No wallpapers assigned to this theme")
        horizontalAlignment:Text.AlignHCenter;color:Theme.paletteMuted;font.family:Theme.fontFamily;font.pixelSize:13
    }
    Text {
        anchors.right:parent.right;anchors.bottom:parent.bottom;anchors.bottomMargin:0
        visible:!root.compact
        text:Tr.t("Enter to apply");font.family:Theme.fontFamily;font.pixelSize:12;color:"#85837c"
    }
    Item {
        visible:root.compact;anchors.left:parent.left;anchors.right:parent.right;anchors.bottom:parent.bottom;height:16
        Text {width:parent.width*.6;elide:Text.ElideRight;text:root.onPalette?root.selected?.name||"":(root.selected?.path||"").split("/").pop();font.family:Theme.fontFamily;font.pixelSize:12;color:"#85837c"}
        Text {anchors.right:parent.right;text:(root.entries.length?`${strip.current+1}/${root.entries.length}`:"0/0")+"  ·  "+Tr.t("Enter to apply");font.family:Theme.fontFamily;font.pixelSize:12;color:"#85837c"}
    }

}
