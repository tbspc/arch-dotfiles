pragma Singleton
import QtQuick
import Quickshell.Io
QtObject {
    id:root
    property bool ready:false
    readonly property var modules:{
        const out=[{id:"bar",name:"Bar / Island"},{id:"summary",name:"Calendar and media"}]
        for(const p of ModuleService.catalogue)if(p.width>0&&!["clock","pet"].includes(p.id)&&!out.some(e=>e.id===p.id))out.push({id:p.id,name:p.name})
        for(const p of ControlsService.doors)if(p.panel&&!out.some(e=>e.id===p.panel))out.push({id:p.panel,name:p.label})
        return out
    }
    function capture(id:string):var {
        const v={appearance:SettingsService.copy(SettingsService.moduleAppearance[id])||{},rounding:SettingsService.moduleRounding[id]??null,elements:SettingsService.copy(SettingsService.moduleElements[id])||{}}
        if(id==="bar")v.island=IslandPresetService.capture()
        if(id==="launcher")v.launcher=LauncherPresetService.capture()
        if(id==="summary")v.options={islandHoverDesign:SettingsService.islandHoverDesign,islandHoverLayout:SettingsService.copy(SettingsService.islandHoverLayout),islandHoverTopLeft:SettingsService.islandHoverTopLeft,islandHoverTopRight:SettingsService.islandHoverTopRight,islandHoverDateFollowBar:SettingsService.islandHoverDateFollowBar,islandHoverDatePosition:SettingsService.islandHoverDatePosition,islandHoverMediaAutoHide:SettingsService.islandHoverMediaAutoHide}
        if(id==="controls")v.options={centreDesign:SettingsService.centreDesign}
        if(id==="appearance")v.options={wallpaperPickerDesign:SettingsService.wallpaperPickerDesign}
        if(id==="palette")v.options={themePickerDesign:SettingsService.themePickerDesign}
        if(id==="notes")v.options={notesBodyFont:SettingsService.notesBodyFont,notesHandwriting:SettingsService.notesHandwriting}
        return v
    }
    function seed():void {
        if(!ready||!SettingsService.arrived)return
        const next=SettingsService.copy(store.originals)||{};let changed=false
        for(const item of root.modules)if(next[item.id]===undefined){next[item.id]=root.capture(item.id);changed=true}
        if(changed)store.originals=next
    }
    function builtin(id:string,compact:bool):var {
        const v=SettingsService.copy(store.originals[id]||root.capture(id))
        const fixed=["summary","controls","overview","appearance","palette","barpresets","launcher"].includes(id)
        v.appearance={widthScale:fixed||compact?100:108,heightScale:fixed||compact?100:112,padding:id==="summary"?0:compact?(fixed?12:4):(fixed?20:14),opacity:100}
        v.rounding=compact?12:24;v.elements={}
        if(id==="summary")v.options={islandHoverDesign:compact?"compact":"status",islandHoverLayout:{enabled:false}}
        if(id==="controls")v.options={centreDesign:"original"}
        if(id==="appearance")v.options={wallpaperPickerDesign:"carousel"}
        if(id==="palette")v.options={themePickerDesign:"carousel"}
        if(id==="bar")v.island=SettingsService.copy(IslandPresetService.builtins.find(p=>p.id===(compact?"compact":"balanced")).values)
        if(id==="launcher"){v.launcher=SettingsService.copy(LauncherPresetService.builtins.find(p=>p.id===(compact?"compact":"spotlight")).values);v.appearance={};v.rounding=v.launcher.launcherStyle.cornerRadius}
        return v
    }
    function list(id:string):var {
        const original=store.originals[id]
        return (original?[{id:"original",name:"Original",description:"The configuration saved when module presets were added.",values:SettingsService.copy(original),editable:false}]:[])
            .concat([{id:"compact",name:"Compact",description:"Tighter corners and a compact layout.",values:root.builtin(id,true),editable:false},{id:"spacious",name:"Spacious",description:"More room, softer corners and comfortable spacing.",values:root.builtin(id,false),editable:false}])
            .concat(id==="summary"?[{"id": "reference-compact-hover", "name": "Reference · Compact hover", "description": "720 × 76 reference hover layout, with live bar styling.", "values": {"appearance": {"padding": 0, "opacity": 100, "widthScale": 100, "heightScale": 100}, "rounding": 28, "elements": {}, "options": {"islandHoverDesign": "reference-compact", "islandHoverLayout": {"enabled": true, "width": 720, "height": 76, "clockSize": 25, "dateSize": 14, "dateGap": 10, "clockX": 0, "clockY": 0, "leftPadding": 33, "rightPadding": 33, "leftY": 12, "rightY": 12, "headerY": 6, "headerHeight": 28, "headerSize": 13, "headerIconSize": 14, "headerLeftX": 38, "headerRightX": 35, "workspaceScale": 100, "signalScale": 100, "batteryScale": 100, "workspaceWidth": 6, "workspaceHeight": 12, "workspaceInactiveWidth": 5, "workspaceInactiveHeight": 8, "workspaceGap": 4, "followBarStyle": true}, "islandHoverTopLeft": "desktop", "islandHoverTopRight": "notifications", "islandHoverDateFollowBar": false, "islandHoverDatePosition": "right"}}, "editable": false}]:[])
            .concat(id==="summary"?[{"id": "reference-media-hover", "name": "Reference · Media hover", "description": "720 × 138 hover view with a centred mini player and live bar styling.", "values": {"appearance": {"padding": 0, "opacity": 100, "widthScale": 100, "heightScale": 100}, "rounding": 32, "elements": {}, "options": {"islandHoverDesign": "reference-media", "islandHoverLayout": {"enabled": true, "width": 720, "height": 138, "clockSize": 25, "dateSize": 14, "dateGap": 10, "clockX": 0, "clockY": -38, "leftPadding": 33, "rightPadding": 33, "leftY": 12, "rightY": 12, "headerY": 40, "headerHeight": 28, "headerSize": 13, "headerIconSize": 14, "headerLeftX": 38, "headerRightX": 35, "workspaceScale": 100, "signalScale": 100, "batteryScale": 100, "workspaceWidth": 6, "workspaceHeight": 12, "workspaceInactiveWidth": 5, "workspaceInactiveHeight": 8, "workspaceGap": 4, "followBarStyle": true, "mediaEnabled": true, "mediaWidth": 280, "mediaHeight": 56, "mediaX": 0, "mediaY": 59, "mediaTitleSize": 13, "mediaArtistSize": 11, "mediaArtSize": 40, "mediaControls": false}, "islandHoverTopLeft": "desktop", "islandHoverTopRight": "notifications", "islandHoverDateFollowBar": false, "islandHoverDatePosition": "right", "islandHoverMediaAutoHide": false}}, "editable": false}]:[])
            .concat(id==="controls"?[{id:"reference-control-center",name:"Reference · Control Centre",description:"Compact rounded toggles, wide sliders and a notification list.",values:{appearance:{padding:16,opacity:100},rounding:34,elements:{},options:{centreDesign:"reference"}},editable:false}]:[])
            .concat(["appearance","palette"].includes(id)?[{id:"reference-theme-strip",name:"Reference · Theme Strip",description:"Search, six colour swatches, raised selection and a compact footer.",values:{appearance:{padding:16,opacity:100},rounding:32,elements:{},options:id==="palette"?{themePickerDesign:"reference"}:{wallpaperPickerDesign:"reference"}},editable:false}]:[])
            .concat(id==="appearance"?[{id:"reference-wallpaper-gallery",name:"Reference · Wallpaper Gallery",description:"Reference wallpaper cards, heading, theme label and a filename footer.",values:{appearance:{padding:16,opacity:100,widthScale:100,heightScale:100},rounding:34,elements:{},options:{wallpaperPickerDesign:"gallery"}},editable:false}]:[])
            .concat(SettingsService.copy(store.customs[id])||[])
    }
    function wallpaperDesign(style:string):void {
        if(!["carousel","reference","gallery"].includes(style)||!SettingsService.arrived)return
        for(const id of ["appearance"]){
            const list=root.list(id)
            if(style!=="carousel"&&!list.some(p=>p.name==="Before wallpaper designs"))root.save(id,"Before wallpaper designs")
            const p=style==="carousel"?list.find(p=>p.name==="Before wallpaper designs")||list.find(p=>p.id==="original"):list.find(p=>p.id===(style==="gallery"?"reference-wallpaper-gallery":"reference-theme-strip"))
            if(p)root.apply(id,p.values)
        }
        SettingsService.set("wallpaperPickerDesign",style)
    }
    function apply(id:string,values:var):void {
        if(!SettingsService.arrived)return
        if(id==="controls")SettingsService.set("centreDesign",values.options?.centreDesign||"original")
        if(id==="appearance")SettingsService.set("wallpaperPickerDesign",values.options?.wallpaperPickerDesign||"carousel")
        if(id==="palette")SettingsService.set("themePickerDesign",values.options?.themePickerDesign||values.options?.wallpaperPickerDesign||"carousel")
        if(id==="bar"&&values.island)IslandPresetService.apply(values.island)
        if(id==="launcher"&&values.launcher)LauncherPresetService.assign(values.launcher)
        for(const pair of [["moduleAppearance","appearance"],["moduleElements","elements"]]){
            const map=SettingsService.copy(SettingsService[pair[0]])||{}
            if(Object.keys(values[pair[1]]||{}).length)map[id]=SettingsService.copy(values[pair[1]])
            else delete map[id]
            SettingsService.set(pair[0],map)
        }
        const round=SettingsService.copy(SettingsService.moduleRounding)||{}
        if(typeof values.rounding==="number")round[id]=values.rounding;else delete round[id]
        SettingsService.set("moduleRounding",round)
        for(const key of Object.keys(values.options||{}))if(!["islandSummary","islandSummaryMode"].includes(key)&&!(id==="palette"&&key==="wallpaperPickerDesign"))SettingsService.set(key,values.options[key])
    }
    function save(id:string,name:string):void {
        if(!ready)return
        const all=SettingsService.copy(store.customs)||{}
        all[id]=(all[id]||[]).concat([{id:"module-"+Date.now(),name:(name||"My module").trim().slice(0,40),description:"Your saved module configuration.",values:root.capture(id),editable:true}])
        store.customs=all
    }
    function update(id:string,preset:string):void{const all=SettingsService.copy(store.customs)||{};all[id]=(all[id]||[]).map(p=>p.id===preset?Object.assign({},p,{values:root.capture(id)}):p);store.customs=all}
    function remove(id:string,preset:string):void{const all=SettingsService.copy(store.customs)||{};all[id]=(all[id]||[]).filter(p=>p.id!==preset);store.customs=all}
    readonly property Connections settingsReady:Connections{target:SettingsService;function onArrivedChanged(){root.seed()}}
    readonly property FileView file:FileView{
        path:SettingsService.stateDirectory+"/module-presets.json";watchChanges:true
        onFileChanged:reload()
        onLoaded:{root.ready=true;root.seed()}
        onLoadFailed:error=>{if(error===FileViewError.FileNotFound){root.ready=true;root.seed()}}
        onAdapterUpdated:if(root.ready)saver.restart()
        readonly property Timer saver:Timer{interval:0;onTriggered:root.file.writeAdapter()}
        JsonAdapter{id:store;property var originals:({});property var customs:({})}
    }
}
