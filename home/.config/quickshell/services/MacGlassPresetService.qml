pragma Singleton
import QtQuick
import Quickshell.Io
QtObject {
    id:root
    property bool ready:false
    readonly property var keys:["surfaceStyle","desktopGround","dockGround","terminalGround","terminalFrost","nautilusBlur","nautilusFrost","settingsBlur","settingsFrost","lockFieldMaterial","macGlassRefractionRange","macGlassRefractionMode","macGlassEdgeWidth","macGlassSpread","macGlassCentreStrength","macGlassFlow","macGlassBarProfile","macGlassProfileTarget","macGlassRefraction","macGlassBlur","macGlassTint","macGlassShine","macGlassLive","macGlassWindows","macGlassSettings","macGlassTerminal","macGlassNautilus","macGlassFileDialogs","macGlassFileDialogOpacity","lockGlassBlur","lockGlassRefraction","lockGlassTint","lockGlassShine"]
    readonly property var saved:SettingsService.copy(store.presets)||[]
    function capture():var {
        const v={}
        for(const key of root.keys)v[key]=SettingsService.copy(SettingsService[key])
        v.settingsOpaque=SettingsDesignService.style.opaque===true
        v.launcherSurfaceTone=SettingsService.launcherStyle.surfaceTone||"theme"
        return v
    }
    function complete(value:var):var {
        const v=value||{},out={}
        for(const key of root.keys)out[key]=SettingsService.copy(v[key]!==undefined&&SettingsService.accepts(key,v[key])?v[key]:SettingsService.pristine[key])
        out.settingsOpaque=typeof v.settingsOpaque==="boolean"?v.settingsOpaque:true
        out.launcherSurfaceTone=["theme","grey","black"].includes(v.launcherSurfaceTone)?v.launcherSurfaceTone:"theme"
        return out
    }
    function stable(v:var):string {
        if(v===null||typeof v!=="object")return JSON.stringify(v)
        if(Array.isArray(v))return "["+v.map(x=>root.stable(x)).join(",")+"]"
        return "{"+Object.keys(v).sort().map(k=>JSON.stringify(k)+":"+root.stable(v[k])).join(",")+"}"
    }
    function matches(value:var):bool {return SettingsService.arrived && root.stable(root.capture())===root.stable(root.complete(value))}
    function apply(value:var):void {
        if(!SettingsService.arrived)return
        const v=root.complete(value)
        for(const key of root.keys)SettingsService.set(key,v[key])
        SettingsDesignService.set("opaque",v.settingsOpaque)
        SettingsService.set("launcherStyle",Object.assign({},SettingsService.launcherStyle,{surfaceTone:v.launcherSurfaceTone}))
    }
    function save(name:string):string {
        if(!root.ready||!SettingsService.arrived)return ""
        const id="macglass-"+Date.now()+"-"+Math.random().toString(36).slice(2,6)
        store.presets=root.saved.concat([{id:id,name:(name||"My glass").trim().slice(0,60)||"My glass",description:"Saved glass values and enabled targets, including separate bar/module and window profiles.",values:root.capture()}])
        return id
    }
    function update(id:string):void {if(root.ready&&SettingsService.arrived)store.presets=root.saved.map(p=>p.id===id?Object.assign({},p,{values:root.capture()}):p)}
    function remove(id:string):void {if(root.ready)store.presets=root.saved.filter(p=>p.id!==id)}
    function design(blur:int,tint:int,bend:int):var {
        const v=root.complete({surfaceStyle:"tahoe",desktopGround:"tahoe",dockGround:"tahoe",terminalGround:"tahoe",lockFieldMaterial:"tahoe",macGlassSettings:true,macGlassTerminal:true,macGlassWindows:false,macGlassBlur:blur,macGlassTint:tint,macGlassRefraction:bend,macGlassShine:20,settingsOpaque:false,launcherSurfaceTone:"theme",macGlassBarProfile:{macGlassBlur:blur,macGlassTint:tint,macGlassRefraction:bend,macGlassShine:20,macGlassRefractionRange:180,macGlassEdgeWidth:12,macGlassSpread:8}})
        return v
    }
    readonly property var designs:[
        {id:"macglass-clear",name:"Clear glass",description:"Light blur and a clear rim across the bar, Settings, terminal and password pill.",values:root.design(2,12,70)},
        {id:"macglass-soft",name:"Soft glass",description:"More blur and a gentle tint, with restrained refraction.",values:root.design(8,35,65)},
        {id:"macglass-balanced",name:"Balanced glass",description:"A subtle balance of blur, refraction and edge light.",values:root.design(5,24,100)}
    ]
    function seed():void {
        if(root.ready&&SettingsService.arrived&&!store.initialized){store.initialized=true;root.save("My current glass")}
    }
    readonly property Connections settings:Connections {target:SettingsService;function onArrivedChanged(){root.seed()}}
    readonly property FileView file:FileView {
        path:SettingsService.stateDirectory+"/macglass-presets.json";watchChanges:true;printErrors:false
        onFileChanged:reload()
        onLoaded:{root.ready=true;root.seed()}
        onLoadFailed:error=>{if(error===FileViewError.FileNotFound){root.ready=true;root.seed()}}
        onAdapterUpdated:if(root.ready)saver.restart()
        readonly property Timer saver:Timer {interval:80;onTriggered:root.file.writeAdapter()}
        JsonAdapter {id:store;property bool initialized:false;property var presets:[]}
    }
    readonly property IpcHandler api:IpcHandler {
        target:"glass-presets"
        function status():string {return JSON.stringify({ready:root.ready,saved:root.saved.map(p=>({id:p.id,name:p.name})),builtins:root.designs.length})}
        function save(name:string):string {return root.save(name)}
        function update(id:string):void {root.update(id)}
        function remove(id:string):void {root.remove(id)}
        function apply(id:string):bool {const p=root.saved.concat(root.designs).find(p=>p.id===id);if(!p)return false;root.apply(p.values);return true}
    }
}
