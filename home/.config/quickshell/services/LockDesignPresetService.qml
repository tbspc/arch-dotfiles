pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
QtObject {
    id:root
    property bool ready:false
    readonly property var keys:["lockDesign","lockClock","lockClockSize","lockDateSize","lockClockTop","lockClockOpacity","lockDateOpacity","lockClockShadow","lockShowsDate","lockTimeFormat","lockFont","lockInk","lockAvatarSize","lockAccountBottom","lockProfileGap","lockPromptGap","lockNameSize","lockFieldWidth","lockFieldHeight","lockFieldOpacity","lockFieldBorderOpacity","lockFieldMaterial","lockDim","lockBackdrop","lockVibrance","lockExtraBlur","lockBlur","lockStatus","lockHint","lockIdleHint","lockPlaceholder","lockMusic","lockMusicGround"]
    readonly property var saved:SettingsService.copy(store.presets)||[]
    readonly property var designs:[{id:"reference-minimal",name:"Reference · Minimal",description:"Large SF clock, full date, user circle and a small frosted password pill. Uses your current wallpaper.",values:root.reference()}]
    function reference():var {
        const scale=(Quickshell.screens[0]?.width||1920)/1918
        return {lockDesign:"reference",lockClock:"inline",lockClockSize:Math.round(146*scale),lockDateSize:Math.round(26*scale),lockClockTop:Math.round(128*scale),lockClockOpacity:80,lockDateOpacity:100,lockClockShadow:8,lockShowsDate:true,lockTimeFormat:"HH:mm",lockFont:"sf-display",lockInk:"white",lockAvatarSize:Math.round(58*scale),lockAccountBottom:Math.round(49*scale),lockProfileGap:Math.round(22*scale),lockPromptGap:Math.round(20*scale),lockNameSize:Math.round(18*scale),lockFieldWidth:Math.round(196*scale),lockFieldHeight:Math.round(32*scale),lockFieldOpacity:23,lockFieldBorderOpacity:12,lockFieldMaterial:"classic",lockDim:0,lockVibrance:42,lockExtraBlur:0,lockBlur:64,lockStatus:true,lockHint:true,lockIdleHint:"Press Any Key to Enter Password",lockPlaceholder:"",lockMusic:"off",lockMusicGround:"desktop"}
    }
    function capture():var {const out={};for(const k of keys)out[k]=SettingsService.copy(SettingsService[k]);return out}
    function matches(v:var):bool{return keys.every(k=>v[k]===undefined||JSON.stringify(v[k])===JSON.stringify(SettingsService[k]))}
    function apply(v:var):void{if(SettingsService.arrived)for(const k of keys)if(v[k]!==undefined)SettingsService.set(k,v[k])}
    function save(name:string):void{if(ready)store.presets=saved.concat([{id:"lock-design-"+Date.now(),name:(name||"My lock screen").trim().slice(0,50),values:capture()}])}
    function update(id:string):void{store.presets=saved.map(p=>p.id===id?Object.assign({},p,{values:capture()}):p)}
    function remove(id:string):void{store.presets=saved.filter(p=>p.id!==id)}
    function seed():void{if(ready&&SettingsService.arrived&&!store.initialized){store.initialized=true;save("Before reference preset")}}
    readonly property Connections settingsReady:Connections{target:SettingsService;function onArrivedChanged(){root.seed()}}
    readonly property FileView file:FileView {
        path:SettingsService.stateDirectory+"/lock-design-presets.json";watchChanges:true
        onFileChanged:reload()
        onLoaded:{root.ready=true;root.seed()}
        onLoadFailed:error=>{if(error===FileViewError.FileNotFound){root.ready=true;root.seed()}}
        onAdapterUpdated:if(root.ready)saver.restart()
        readonly property Timer saver:Timer{interval:0;onTriggered:root.file.writeAdapter()}
        JsonAdapter{id:store;property bool initialized:false;property var presets:[]}
    }
}
