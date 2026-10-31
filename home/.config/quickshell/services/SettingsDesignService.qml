pragma Singleton
import QtQuick
import Quickshell.Io
QtObject {
    id:root
    property bool ready:false
    readonly property var defaults:({background:"",cardBackground:"",sidebarBackground:"",navigation:"sidebar",sidebarWidth:206,gap:12,cardRadius:12,groupGap:20,rowHeight:48,rowPadding:8,navRowHeight:30,outline:false,windowWidth:980,windowHeight:680})
    readonly property var raw:SettingsService.settingsDesign||{}
    readonly property bool forma:root.raw.appearanceVariant === "forma" || root.modern
    readonly property bool modern:root.raw.appearanceVariant === "settings-studio"
    readonly property var colourPalettes:({
        dark:{background:"#171c17",sidebarBackground:"#121712",cardBackground:"#20271f",fieldBackground:"#293127",borderColor:"#364033",textColor:"#edf1e9",mutedColor:"#acb6a5",hoverColor:"#303b2c"},
        light:{background:"#f3f5ef",sidebarBackground:"#e9eee4",cardBackground:"#ffffff",fieldBackground:"#edf2e8",borderColor:"#d0dac9",textColor:"#1c281d",mutedColor:"#5b6b57",hoverColor:"#dce7d5"},
        black:{background:"#000000",sidebarBackground:"#080b08",cardBackground:"#101610",fieldBackground:"#1a2319",borderColor:"#2c382a",textColor:"#eff4eb",mutedColor:"#a9b6a2",hoverColor:"#253122"}
    })
    readonly property var surfaceTones:[
        {id:"forest",name:"Green",swatch:"#507955"},{id:"neutral",name:"Neutral",swatch:"#555555"},
        {id:"bar-grey",name:"Bar grey",swatch:"#141414"},{id:"black",name:"Black",swatch:"#000000"},
        {id:"blue",name:"Blue",swatch:"#4f85d0"},{id:"teal",name:"Teal",swatch:"#399b92"},
        {id:"purple",name:"Purple",swatch:"#9971bd"},{id:"pink",name:"Pink",swatch:"#c06f9c"},
        {id:"red",name:"Red",swatch:"#bd6066"},{id:"orange",name:"Orange",swatch:"#be8550"},
        {id:"yellow",name:"Yellow",swatch:"#b6a44e"}
    ]
    function blend(a:string,b:string,amount:real):string {
        const rgb=[1,3,5].map(i=>Math.round(parseInt(a.slice(i,i+2),16)*(1-amount)+parseInt(b.slice(i,i+2),16)*amount))
        return "#"+rgb.map(v=>v.toString(16).padStart(2,"0")).join("")
    }
    function paletteFor(mode:string,tone:string):var {
        tone=tone||root.raw.surfaceTone||"forest"
        if(tone==="forest")return root.colourPalettes[mode]||root.colourPalettes.dark
        if(tone==="bar-grey" && mode==="dark")return {background:"#141414",sidebarBackground:"#101010",cardBackground:"#1c1c1c",fieldBackground:"#252525",borderColor:"#383838",textColor:"#f1f1f1",mutedColor:"#aaaaaa",hoverColor:"#303030"}
        if(tone==="black" && mode!=="light")return {background:"#000000",sidebarBackground:"#070707",cardBackground:"#0e0e0e",fieldBackground:"#181818",borderColor:"#2b2b2b",textColor:"#f1f1f1",mutedColor:"#aaaaaa",hoverColor:"#252525"}
        const colour=root.surfaceTones.find(t=>t.id===tone)?.swatch||"#777777"
        const neutral=["neutral","bar-grey","black"].includes(tone)
        const mix=(base,amount)=>root.blend(base,colour,neutral?0:amount)
        if(mode==="light")return {background:mix("#f5f5f5",.035),sidebarBackground:mix("#ededed",.065),cardBackground:"#ffffff",fieldBackground:mix("#eeeeee",.05),borderColor:mix("#d8d8d8",.1),textColor:"#20242a",mutedColor:mix("#64686b",.1),hoverColor:mix("#e1e1e1",.07)}
        if(mode==="black")return {background:"#000000",sidebarBackground:mix("#070707",.035),cardBackground:mix("#0f0f0f",.07),fieldBackground:mix("#181818",.1),borderColor:mix("#292929",.15),textColor:"#f0f2f4",mutedColor:mix("#aaaaaa",.12),hoverColor:mix("#252525",.12)}
        return {background:mix("#161616",.1),sidebarBackground:mix("#101010",.08),cardBackground:mix("#202020",.12),fieldBackground:mix("#292929",.14),borderColor:mix("#373737",.18),textColor:"#f0f2f4",mutedColor:mix("#a6a6a6",.15),hoverColor:mix("#303030",.16)}
    }
    readonly property var accents:[{name:"Forest",colour:"#a2d0ad"},{name:"Ocean",colour:"#80aed4"},{name:"Clay",colour:"#d09a75"},{name:"Olive",colour:"#b8bd78"},{name:"Iris",colour:"#b7a0cf"},{name:"Rose",colour:"#d28fa5"},{name:"Stone",colour:"#aab3a5"}]
    readonly property var formaDefaults:Object.assign({},root.defaults,{
        navigation:"studio",appearanceVariant:"forma",colourMode:"dark",surfaceTone:"forest",accentColor:"#a2d0ad",useThemeAccent:false,
        sidebarWidth:228,gap:22,cardRadius:15,groupGap:22,rowHeight:66,rowPadding:12,navRowHeight:40,
        windowWidth:1320,windowHeight:980,controlHeight:34,controlFontSize:13,sliderTrackHeight:5,sliderThumbSize:17,
        contentMargin:42,sidebarPadding:12,headerSize:32,headerIcon:false,bodyFont:"",headingFont:"",textScale:100,
        showBreadcrumbs:true,showSavedStatus:true,showProfile:false,showSearch:true,showPageDescription:true,
        showFooter:true,showLivePreview:true,showHelp:true,showCategoryLabels:true,sidebarIcons:true,sidebarIconSize:17,
        navRadius:10,controlRadius:8,buttonRadius:8,fieldRadius:8,borderWidth:1,cardPadding:18,sidebarSpacing:10,
        tabRadius:17,showCardTitles:true,rowDivider:true,brandName:"Hyprland",colourOverrides:{}
    })
    readonly property var modernDefaults:Object.assign({},root.formaDefaults,{
        navigation:"studio",appearanceVariant:"settings-studio",opaque:true,colourMode:"light",surfaceTone:"neutral",
        background:"#fdfcf9",sidebarBackground:"#f6f3ee",cardBackground:"#fefdfb",fieldBackground:"#fdfcf9",
        textColor:"#1e1a16",mutedColor:"#77706b",accentColor:"#bc5a29",borderColor:"#e1ddd8",fieldBorderColor:"#dbd7d2",
        hoverColor:"#eeeae4",selectedColor:"#e7e2dc",useThemeAccent:false,
        sidebarWidth:240,windowWidth:1080,windowHeight:700,gap:24,cardRadius:14,groupGap:28,rowHeight:60,rowPadding:12,
        navRowHeight:36,controlHeight:32,controlFontSize:13,controlRadius:8,buttonRadius:8,fieldRadius:8,
        contentMargin:40,contentWidth:592,sidebarPadding:12,sidebarSpacing:8,headerSize:20,headerIcon:true,
        bodyFont:"Geist",headingFont:"Geist",sliderTrackHeight:4,sliderThumbSize:14,navRadius:8,
        showProfile:false,showFooter:false,showLivePreview:false,showHelp:false,tabRadius:7,cardPadding:16
    })
    function modernPalette(mode:string,tone:string):var {
        if(tone!=="neutral")return root.paletteFor(mode,tone)
        if(mode==="light")return {background:"#fdfcf9",sidebarBackground:"#f6f3ee",cardBackground:"#fefdfb",fieldBackground:"#fdfcf9",borderColor:"#e1ddd8",fieldBorderColor:"#dbd7d2",textColor:"#1e1a16",mutedColor:"#77706b",hoverColor:"#eeeae4",selectedColor:"#e7e2dc"}
        if(mode==="black")return {background:"#000000",sidebarBackground:"#080808",cardBackground:"#101010",fieldBackground:"#171717",borderColor:"#2b2a28",fieldBorderColor:"#37342f",textColor:"#f5f1e9",mutedColor:"#a9a39b",hoverColor:"#24211d",selectedColor:"#322b24"}
        return {background:"#181715",sidebarBackground:"#201e1a",cardBackground:"#22201c",fieldBackground:"#292621",borderColor:"#39352f",fieldBorderColor:"#484139",textColor:"#f5f1e9",mutedColor:"#b2aaa0",hoverColor:"#322e28",selectedColor:"#3c3329"}
    }
    // Save the design before temporary material effects are applied.
    readonly property var designStyle:{
        const base=Object.assign({},root.defaults,root.raw)
        const mode=root.raw.colourMode||(root.modern?"light":"dark")
        const tone=root.raw.surfaceTone||(root.modern?"neutral":"forest")
        if(!root.forma && !root.modern)return base
        const palette=root.modern?root.modernPalette(mode,tone):root.paletteFor(mode,tone)
        const overrides=root.raw.colourOverrides?.[mode+":"+tone]||(tone==="forest"?root.raw.colourOverrides?.[mode]:{})||{}
        return Object.assign({},root.modern?root.modernDefaults:root.formaDefaults,base,palette,overrides)
    }
    readonly property var style:{
        const palette=root.designStyle
        if(SettingsService.settingsBlur && !SettingsService.gameMode){
            const f=SettingsService.settingsFrost||{},alpha=Math.max(.05,Math.min(.95,Number(f.opacity??35)/100))
            return Object.assign({},palette,{
                background:Qt.alpha(palette.background||"#161616",alpha),
                titlebarBackground:Qt.alpha(palette.sidebarBackground||"#101010",alpha*.35),
                sidebarBackground:Qt.alpha(palette.sidebarBackground||"#101010",alpha*.35),
                cardBackground:Qt.alpha(palette.cardBackground||"#202020",alpha*.5),
                fieldBackground:Qt.alpha(palette.fieldBackground||"#292929",alpha*.65)})
        }
        if(palette.opaque===true || !SettingsService.macGlassSettings || SettingsService.gameMode)return palette
        const light=palette.colourMode==="light"
        return Object.assign({},palette,{background:light?"#24ffffff":"#24131a24",sidebarBackground:light?"#20ffffff":"#20ffffff",cardBackground:light?"#28ffffff":"#12ffffff",fieldBackground:light?"#38ffffff":"#34171b24",borderColor:light?"#55707888":"#44ffffff",textColor:light?"#182333":"#ffffff",mutedColor:light?"#39495a":"#d2dce8",hoverColor:light?"#60ffffff":"#40ffffff"})
    }
    function set(key:string,value:var):void {SettingsService.set("settingsDesign",Object.assign({},root.raw,{[key]:value}))}
    function setColour(key:string,value:string):void {
        if(!/^#[0-9a-fA-F]{6}$/.test(value))return
        const all=SettingsService.copy(root.raw.colourOverrides)||{}, mode=(root.raw.colourMode||"dark")+":"+(root.raw.surfaceTone||"forest")
        all[mode]=Object.assign({},all[mode]||{},{[key]:value})
        root.set("colourOverrides",all)
    }
    function clearColours():void {const all=SettingsService.copy(root.raw.colourOverrides)||{};delete all[(root.raw.colourMode||"dark")+":"+(root.raw.surfaceTone||"forest")];if((root.raw.surfaceTone||"forest")==="forest")delete all[root.raw.colourMode||"dark"];root.set("colourOverrides",all)}
    function useForma():void {root.apply(root.formaDefaults)}
    readonly property IpcHandler api:IpcHandler {
        target:"settings-appearance"
        function useNewDesign():void {root.useForma()}
        function save(name:string):void {root.save(name)}
        function surface(name:string):void {if(root.surfaceTones.some(t=>t.id===name))root.set("surfaceTone",name)}
        function profileCard(visible:bool):void {root.set("showProfile",visible)}
        function mode(name:string):void {if(["light","dark","black"].includes(name))root.set("colourMode",name)}
        function simplifyLibrary():void {if(root.ready)store.presets=[]}
        function status():string {return JSON.stringify({forma:root.forma,modern:root.modern,mode:root.style.colourMode||"legacy",surface:root.style.surfaceTone||"forest",background:root.style.background,text:root.style.textColor||"",presets:root.designs.map(p=>p.name),saved:root.saved.map(p=>p.name)})}
    }
    readonly property var saved:SettingsService.copy(store.presets)||[]
    readonly property var designs:[
        {id:"default",name:"Default",description:"The original simple settings layout.",values:root.defaults},
        {id:"studio",name:"Studio",description:"A calm indigo sidebar, colourful navigation icons, bordered cards and a dedicated Profile page, inspired by your reference.",values:Object.assign({},root.defaults,{navigation:"studio",background:"#151725",sidebarBackground:"#1b1e30",cardBackground:"#151725",fieldBackground:"#1b1e30",borderColor:"#2b304a",accentColor:"#59bff4",sidebarWidth:260,gap:24,cardRadius:18,groupGap:28,rowHeight:74,rowPadding:14,navRowHeight:42,windowWidth:1140,windowHeight:880,controlHeight:34,controlFontSize:13,sliderTrackHeight:5,sliderThumbSize:18,useThemeAccent:false})},
        {id:"settings-studio",name:"Settings Studio",description:"Warm ivory surfaces, a compact sidebar and smooth page transitions, based on your Settings Studio reference.",values:root.modernDefaults}
    ]
    function apply(values:var):void{SettingsService.set("settingsDesign",SettingsService.copy(values)||{})}
    function save(name:string):void{if(!ready||!SettingsService.arrived)return;const id="settings-"+Date.now();store.presets=root.saved.concat([{id,name:(name||"My settings design").trim().slice(0,40),values:SettingsService.copy(root.designStyle)}])}
    function update(id:string):void{store.presets=root.saved.map(p=>p.id===id?Object.assign({},p,{values:SettingsService.copy(root.designStyle)}):p)}
    function remove(id:string):void{store.presets=root.saved.filter(p=>p.id!==id)}
    function seed():void{if(ready&&SettingsService.arrived&&!store.initialized){store.initialized=true;root.save("My original settings")}}
    readonly property Connections settingsReady:Connections{target:SettingsService;function onArrivedChanged(){root.seed()}}
    readonly property FileView file:FileView{
        path:SettingsService.stateDirectory+"/settings-designs.json";watchChanges:true
        onFileChanged:reload()
        onLoaded:{root.ready=true;root.seed()}
        onLoadFailed:error=>{if(error===FileViewError.FileNotFound){root.ready=true;root.seed()}}
        onAdapterUpdated:if(root.ready)saver.restart()
        readonly property Timer saver:Timer{interval:0;onTriggered:root.file.writeAdapter()}
        JsonAdapter{id:store;property bool initialized:false;property var presets:[]}
    }
}
