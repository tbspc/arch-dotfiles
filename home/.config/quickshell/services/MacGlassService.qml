pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id:root
    function saveBefore():void {
        if(store.before!==null)return
        const snapshot=SettingsService.snapshot(),before={}
        for(const key of ["surfaceStyle","desktopGround","dockGround","terminalGround","macGlassTerminal","macGlassSettings","macGlassWindows","lockFieldMaterial"])
            before[key]=snapshot[key]
        store.before=before
        SetupPresetService.save("Before MacShell glass")
    }
    function apply():void {
        root.saveBefore()
        BarColourService.apply({surfaceStyle:"tahoe"})
        SettingsService.set("macGlassSettings",true)
        root.terminal(true)
    }
    function restore():void {
        if(!store.before)return
        for(const key of Object.keys(store.before))SettingsService.set(key,store.before[key])
    }
    function terminal(enabled:bool):void {
        if(enabled&&SettingsService.terminalGround!=="tahoe")store.terminalBefore=SettingsService.terminalGround
        SettingsService.set("macGlassTerminal",enabled)
        SettingsService.set("terminalGround",enabled?"tahoe":store.terminalBefore)
    }
    readonly property FileView file:FileView {
        path:SettingsService.stateDirectory+"/macshell-glass.json"
        printErrors:false
        onAdapterUpdated:saver.restart()
        readonly property Timer saver:Timer {interval:80;onTriggered:root.file.writeAdapter()}
        JsonAdapter {id:store;property var before:null;property string terminalBefore:"glass"}
    }
    IpcHandler {target:"mac-glass"
        function apply():void {root.apply()}
        function restore():void {root.restore()}
        function windows(enabled:bool):void {SettingsService.set("macGlassWindows",enabled)}
        function settings(enabled:bool):void {SettingsService.set("macGlassSettings",enabled)}
        function terminal(enabled:bool):void {root.terminal(enabled)}
        function live(enabled:bool):void {SettingsService.set("macGlassLive",enabled)}
        function pill(enabled:bool):void {SettingsService.set("lockFieldMaterial",enabled?"tahoe":"classic")}
        function tune(blur:int,refraction:int,tint:int,shine:int):void {
            SettingsService.set("macGlassBlur",Math.max(0,Math.min(22,blur)))
            SettingsService.set("macGlassRefraction",Math.max(0,Math.min(SettingsService.macGlassRefractionRange,refraction)))
            SettingsService.set("macGlassTint",Math.max(0,Math.min(100,tint)))
            SettingsService.set("macGlassShine",Math.max(0,Math.min(100,shine)))
        }
        function profile(mode:string,range:int,edge:int,spread:int,centre:int,flow:int):void {
            SettingsService.set("macGlassRefractionMode",mode==="full"?"full":"edges")
            SettingsService.set("macGlassRefractionRange",Math.max(100,Math.min(600,range)))
            SettingsService.set("macGlassEdgeWidth",Math.max(1,Math.min(120,edge)))
            SettingsService.set("macGlassSpread",Math.max(0,Math.min(100,spread)))
            SettingsService.set("macGlassCentreStrength",Math.max(0,Math.min(100,centre)))
            SettingsService.set("macGlassFlow",Math.max(0,Math.min(100,flow)))
        }
        function material(value:string):void {if(["classic","glass","liquid","liquid-old","tahoe"].includes(value))BarColourService.apply({surfaceStyle:value})}
        function barProfile(value:string):void {try{const p=JSON.parse(value);if(p&&typeof p==="object"&&!Array.isArray(p))SettingsService.set("macGlassBarProfile",p)}catch(error){}}
        function barTune(blur:int,refraction:int,tint:int,shine:int):void {
            SettingsService.set("macGlassBarProfile",Object.assign({},SettingsService.macGlassBarProfile,{macGlassBlur:Math.max(0,Math.min(22,blur)),macGlassRefraction:Math.max(0,Math.min(600,refraction)),macGlassTint:Math.max(0,Math.min(100,tint)),macGlassShine:Math.max(0,Math.min(100,shine))}))
        }
        function status():string {return JSON.stringify({material:SettingsService.surfaceStyle,windows:SettingsService.macGlassWindows,settings:SettingsService.macGlassSettings,terminal:SettingsService.macGlassTerminal,pill:SettingsService.lockFieldMaterial,blur:SettingsService.macGlassBlur,refraction:SettingsService.macGlassRefraction,tint:SettingsService.macGlassTint,shine:SettingsService.macGlassShine,mode:SettingsService.macGlassRefractionMode,range:SettingsService.macGlassRefractionRange,edge:SettingsService.macGlassEdgeWidth,spread:SettingsService.macGlassSpread,centre:SettingsService.macGlassCentreStrength,flow:SettingsService.macGlassFlow,bar:SettingsService.macGlassBarProfile})}
    }
}
