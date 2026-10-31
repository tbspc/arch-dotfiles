pragma Singleton
import QtQuick
import Quickshell.Io
QtObject {
    id:root
    property bool ready:false
    property var previous:null
    readonly property var keys:["barEntryEnabled","barEntryOnUnlock","barEntryAnimation","barEntryDuration","barEntryHold","barEntryUnlockLead","lockIslandTransition","lockIslandTransitionDuration","lockIslandOpenHold","lockIslandCloseDuration","lockIslandEnabled","lockAnimation","lockUnlockMovement","lockUnlockDuration","lockAnimationDuration","lockAnimationSpeed","lockAnimationMovement","lockAnimationBounciness","lockAnimationRebounds","lockSlideDistance"]
    readonly property var saved:SettingsService.copy(store.presets)||[]
    function design(mode:string,duration:int,movement:string,bounce:int,rebounds:int):var{return {barEntryEnabled:mode!=="none",barEntryOnUnlock:true,barEntryAnimation:movement==="spring"||movement==="bounce"?"bounce":mode==="bar-slide"?"smooth":"fade",barEntryDuration:Math.min(650,Math.max(200,Math.round(duration*.6))),barEntryHold:80,barEntryUnlockLead:140,lockIslandTransition:movement==="spring"||movement==="bounce"?"bounce":"fade",lockIslandTransitionDuration:Math.min(duration,280),lockIslandOpenHold:100,lockIslandCloseDuration:220,lockAnimation:mode,lockAnimationDuration:duration,lockUnlockDuration:0,lockUnlockMovement:"follow",lockAnimationSpeed:100,lockAnimationMovement:movement,lockAnimationBounciness:bounce,lockAnimationRebounds:rebounds,lockSlideDistance:360}}
    readonly property var builtins:[
        {id:"video-reference-fade",name:"Video reference · Lock fade",description:"Measured reference: a 500 ms ease-out blur/fade into the lock screen, then a 170 ms unlock. No extra lock bar. Keeps your blur and vibrance choices.",values:Object.assign(root.design("fade",500,"quint",0,1),{lockUnlockDuration:170,lockUnlockMovement:"glide",lockIslandEnabled:false,barEntryEnabled:false,barEntryOnUnlock:false,barEntryHold:0,barEntryUnlockLead:0})},
        {id:"soft-fade",name:"Soft fade",description:"A calm crossfade in 420 ms.",values:root.design("fade",420,"smooth",0,1)},
        {id:"quick-fade",name:"Quick fade",description:"A short, clean 220 ms crossfade.",values:root.design("fade",220,"glide",0,1)},
        {id:"slow-dissolve",name:"Slow dissolve",description:"A relaxed 850 ms fade.",values:root.design("fade",850,"smooth",0,1)},
        {id:"soft-slide",name:"Soft slide",description:"A subtle slide with a 500 ms fade.",values:root.design("soft-slide",500,"smooth",0,1)},
        {id:"smooth-curtain",name:"Smooth curtain",description:"The island leads a full-screen sheet with smooth easing.",values:root.design("bar-slide",650,"smooth",0,1)},
        {id:"quick-glide",name:"Quick glide",description:"A fast descending curtain that settles gently.",values:root.design("bar-slide",380,"glide",0,1)},
        {id:"soft-spring",name:"Soft spring",description:"A restrained spring with one soft settling movement.",values:root.design("bar-slide",650,"spring",22,1)},
        {id:"gentle-bounce",name:"Gentle bounce",description:"One small rebound, with an unhurried 720 ms descent.",values:root.design("bar-slide",720,"bounce",28,1)},
        {id:"floating-spring",name:"Floating spring",description:"A longer spring with two small, damped rebounds.",values:root.design("bar-slide",850,"spring",35,2)},
        {id:"linear-reveal",name:"Linear reveal",description:"A steady curtain with constant movement.",values:root.design("bar-slide",600,"linear",0,1)},
        {id:"instant",name:"Instant",description:"No transition; lock and unlock immediately.",values:root.design("none",200,"smooth",0,1)}
    ]
    readonly property var designs:root.builtins.filter(p=>!(store.hidden||[]).includes(p.id)).map(p=>Object.assign({},p,store.overrides?.[p.id]||{}))
    function capture():var{const out={};for(const key of root.keys)out[key]=SettingsService[key];return SettingsService.copy(out)}
    function matches(v:var):bool{return root.keys.every(key=>JSON.stringify(SettingsService[key])===JSON.stringify(v[key]!==undefined?v[key]:key==="lockIslandEnabled"?SettingsService[key]:SettingsService.pristine[key]))}
    function apply(v:var):void{if(!SettingsService.arrived)return;previous=root.capture();for(const key of root.keys)SettingsService.set(key,v[key]!==undefined?v[key]:key==="lockIslandEnabled"?SettingsService[key]:SettingsService.pristine[key])}
    function undo():void{if(previous){const v=previous;previous=null;for(const key of root.keys)SettingsService.set(key,v[key])}}
    function save(name:string):void{if(!ready||!SettingsService.arrived)return;store.presets=root.saved.concat([{id:"lock-motion-"+Date.now(),name:(name||"My animation").trim().slice(0,40),values:root.capture()}])}
    function update(id:string):void{if(root.builtins.some(p=>p.id===id))store.overrides=Object.assign({},store.overrides||{},{[id]:{values:root.capture()}});else store.presets=root.saved.map(p=>p.id===id?Object.assign({},p,{values:root.capture()}):p)}
    function remove(id:string):void{if(root.builtins.some(p=>p.id===id))store.hidden=[...(store.hidden||[]),id];else store.presets=root.saved.filter(p=>p.id!==id)}
    function restore():void{store.hidden=[];store.overrides={}}
    function seed():void{if(ready&&SettingsService.arrived&&!store.initialized){store.initialized=true;root.save("My original animation")}}
    readonly property Connections settingsReady:Connections{target:SettingsService;function onArrivedChanged(){root.seed()}}
    readonly property FileView file:FileView{
        path:SettingsService.stateDirectory+"/lock-animation-presets.json";watchChanges:true
        onFileChanged:reload()
        onLoaded:{root.ready=true;root.seed()}
        onLoadFailed:error=>{if(error===FileViewError.FileNotFound){root.ready=true;root.seed()}}
        onAdapterUpdated:if(root.ready)saver.restart()
        readonly property Timer saver:Timer{interval:0;onTriggered:root.file.writeAdapter()}
        JsonAdapter{id:store;property bool initialized:false;property var presets:[];property var overrides:({});property var hidden:[]}
    }
}
