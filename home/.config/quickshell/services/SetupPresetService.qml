pragma Singleton
import QtQuick
import Quickshell.Io
import "../theme"
QtObject {
    id:root
    property bool ready:false
    property var previous:null
    property int revision:0
    readonly property var saved:SettingsService.copy(store.presets)||[]
    function clean(value:var):var {
        if(Array.isArray(value))return value.filter(e=>!(typeof e==="string"&&["pet","board"].includes(e))&&!(e&&typeof e==="object"&&["pet","board"].includes(e.id||e.module))).map(e=>root.clean(e))
        if(value&&typeof value==="object"){
            const result={}
            for(const key of Object.keys(value))if(!["pet","board","islandSummary","islandSummaryMode"].includes(key)&&!key.startsWith("pet")&&!key.includes("Open the pet")&&!key.includes("Open the task board"))result[key]=root.clean(value[key])
            return result
        }
        return value
    }
    function capture():var {return {settings:root.clean(SettingsService.snapshot()),wallpaper:WallpaperService.chosen,palette:ThemeService.activeId}}
    function compose(barId:string,launcherId:string,tone:string):var {
        const anchor=store.original||root.capture()
        const values=SettingsService.complete(root.clean(anchor.settings||{}))
        const bar=IslandPresetService.designs.find(p=>p.id===barId)||IslandPresetService.designs[0]
        if(bar){const finished=IslandPresetService.complete(bar.values);for(const key of IslandPresetService.keys)values[key]=SettingsService.copy(finished[key])}
        values.barStyle="grouped";values.barLeft=[];values.barRight=[]
        values.surfaceStyle=tone==="glass"?"glass":"classic"
        values.floatingBarSurface=tone==="black"?"black":"grey"
        values.barHeight=tone==="glass"?40:38
        values.barMargin=4;values.barSideMargin=18
        const launcher=LauncherPresetService.builtins.find(p=>p.id===launcherId)||LauncherPresetService.builtins[0]
        if(launcher){
            values.launcherStyle=Object.assign({},launcher.values.launcherStyle,{surfaceTone:tone==="grey"?"grey":"theme"})
            values.launcherResults=launcher.values.launcherResults
            values.launcherFits=launcher.values.launcherFits
            values.launcherOrder=launcher.values.launcherOrder
        }
        values.moduleElements={};values.moduleAppearance={};values.moduleRounding={}
        for(const module of ModulePresetService.modules){
            values.moduleRounding[module.id]=tone==="black"?14:20
            if(!["bar","launcher","appearance","barpresets","launcherpresets","setuppresets","documents"].includes(module.id))values.moduleAppearance[module.id]={opacity:100}
        }
        values.moduleRounding.launcher=values.launcherStyle.cornerRadius
        values.motionScale=tone==="black"?85:100
        values.motionCurve="OutCubic"
        values.documentLibraryMotion="slide";values.documentLibraryMotionDuration=180
        values.settingsDesign=Object.assign({},SettingsDesignService.defaults,{navigation:"atlas",background:tone==="black"?"#14171c":"#1b2027",sidebarBackground:"#222831",cardBackground:"#2b333e",sidebarWidth:248,cardRadius:18,gap:18,rowHeight:60,controlHeight:34,controlFontSize:14,sliderTrackHeight:6,sliderThumbSize:18,useThemeAccent:tone!=="black"})
        return {settings:values,wallpaper:anchor.wallpaper||"",palette:anchor.palette||"adaptive"}
    }
    readonly property var designs:[
        {id:"quiet",name:"Quiet",description:"A small floating clock, restrained indicators, a compact launcher and calm charcoal settings.",values:root.compose("aster","compact","black")},
        {id:"graphite",name:"Graphite Studio",description:"A balanced floating bar, dark grey surfaces, readable controls and a comfortable launcher.",values:root.compose("linen","spotlight","grey")},
        {id:"glass",name:"Glass Workspace",description:"A minimal attached notch, wallpaper glass, rounded modules and a clean launcher.",values:root.compose("pin","compact","glass")},
        {id:"chips",name:"Airy Chips",description:"Separate, quiet chips around the clock with a compact launcher and soft module corners.",values:root.compose("halo","compact","grey")}
    ]
    property var pendingValues:null
    property bool transitioning:false
    property real phase:1
    readonly property IpcHandler api:IpcHandler {
        target:"setup-presets"
        function preview():bool {return root.apply(root.capture())}
        function status():string {return JSON.stringify({ready:root.ready,pending:!!root.pendingValues,transitioning:root.transitioning,phase:root.phase,revision:root.revision,style:SettingsService.setupTransitionStyle,duration:SettingsService.setupTransitionDuration})}
    }
    readonly property NumberAnimation phaseOut:NumberAnimation {
        target:root;property:"phase";to:0
        duration:Math.max(40,Math.round(SettingsService.setupTransitionDuration/2))
        easing.type:Easing.OutCubic
        onFinished:root.commit()
    }
    readonly property NumberAnimation phaseIn:NumberAnimation {
        target:root;property:"phase";from:0;to:1
        duration:Math.max(40,Math.round(SettingsService.setupTransitionDuration/2))
        easing.type:SettingsService.setupTransitionStyle==="bounce"?Easing.OutBack:Easing.OutCubic
        easing.overshoot:.65
        onFinished:{root.phase=1;root.transitioning=false}
    }
    function apply(values:var):bool {
        if(!root.ready||!SettingsService.arrived)return false
        if(root.pendingValues){root.pendingValues=values;return true}
        root.previous=root.capture()
        root.pendingValues=values
        root.phaseIn.stop();root.phaseOut.stop()
        if(SettingsService.setupTransitionStyle==="none"){root.commit();return true}
        root.transitioning=true
        root.phaseOut.from=root.phase
        root.phaseOut.restart()
        return true
    }
    function commit():void {
        if(!root.pendingValues)return
        const values=root.pendingValues
        root.pendingValues=null
        IslandPresetService.freezePresentation();IslandPresetService.applying=true
        try {
            SettingsService.adopt(root.clean(values.settings||{}))
            if(values.palette&&(values.palette==="adaptive"||Palettes.byId(values.palette)))ThemeService.setTheme(values.palette)
            if(values.wallpaper&&values.wallpaper!==WallpaperService.chosen)ProfileService.showWallpaper(values.wallpaper)
        } finally {IslandPresetService.applying=false}
        CompositorService.reassert()
        root.revision++
        if(SettingsService.setupTransitionStyle==="none"){root.phase=1;root.transitioning=false}
        else root.phaseIn.restart()
    }
    function undo():void {if(root.previous){const value=root.previous;root.previous=null;root.apply(value);root.previous=null}}
    function save(name:string):string {
        if(!ready||!SettingsService.arrived)return ""
        const id="setup-"+Date.now()+"-"+Math.random().toString(36).slice(2,6)
        store.presets=root.saved.concat([{id:id,name:(name||"My setup").trim().slice(0,40)||"My setup",description:"Your complete saved visual configuration.",values:root.capture()}])
        return id
    }
    function update(id:string):void {store.presets=root.saved.map(p=>p.id===id?Object.assign({},p,{values:root.capture()}):p)}
    function remove(id:string):void {store.presets=root.saved.filter(p=>p.id!==id)}
    function seed():void {
        if(!ready||!SettingsService.arrived||store.initialized)return
        store.original=root.capture();store.initialized=true;root.save("My original complete setup")
    }
    readonly property Connections arrived:Connections {target:SettingsService;function onArrivedChanged(){root.seed()}}
    readonly property FileView file:FileView {
        path:SettingsService.stateDirectory+"/setup-presets.json";watchChanges:true
        onFileChanged:reload()
        onLoaded:{root.ready=true;root.seed()}
        onLoadFailed:error=>{if(error===FileViewError.FileNotFound){root.ready=true;root.seed()}}
        onAdapterUpdated:if(root.ready)saver.restart()
        readonly property Timer saver:Timer {interval:0;onTriggered:root.file.writeAdapter()}
        JsonAdapter {id:store;property bool initialized:false;property var original:null;property var presets:[]}
    }
}
