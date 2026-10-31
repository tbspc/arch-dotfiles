pragma Singleton
import QtQuick
import Quickshell.Io
import "../theme"
QtObject {
    id:root
    property bool ready:false
    property var previous:null
    readonly property var defaults:({surfaceTone:"theme",width:560,height:520,padding:20,cornerRadius:20,fieldHeight:34,rowHeight:48,rowSpacing:2,gap:12,rowRadius:10,rowPadding:12,rowVerticalPadding:6,contentGap:12,textGap:1,iconSize:34,iconPadding:5,iconRadius:7,titleSize:14,subtitleSize:11,searchSize:16,searchIconSize:17,fontFamily:"",titleWeight:500,showIcons:true,iconTiles:true,showSubtitles:true,showPinned:true,showSearchIcon:true,searchIconStyle:"mode",foregroundColor:"",mutedColor:"",highlightColor:"",showDivider:true,placeholder:"Search…",highlightStyle:"soft",highlightOpacity:11,borderOpacity:5,indicatorStyle:"line",indicatorWidth:3,indicatorHeight:60,selectionMotion:"slide",motionDuration:180,hoverSelect:true,wrapNavigation:true,emojiCell:52,emojiSize:28})
    readonly property var style:Object.assign({},root.defaults,SettingsService.launcherStyle||{},{cornerRadius:SettingsService.moduleRadius("launcher",SettingsService.launcherStyle.cornerRadius??root.defaults.cornerRadius),padding:SettingsService.moduleAppearance.launcher?.padding??SettingsService.launcherStyle.padding??root.defaults.padding})
    readonly property var saved:SettingsService.copy(store.presets)||[]
    readonly property var builtins:[
        {id:"reference-compact",name:"Sane Aspect Style",description:"Reference layout: 516 × 370 px, outlined search icon, six two-line app rows and a sliding neutral highlight.",values:root.design({surfaceTone:"black",width:516,height:370,padding:16,cornerRadius:28,fieldHeight:32,searchSize:14,searchIconSize:16,searchIconStyle:"outline",rowHeight:46,rowSpacing:1,gap:12,rowRadius:10,rowPadding:10,rowVerticalPadding:6,contentGap:12,textGap:0,iconSize:32,iconPadding:6,iconRadius:8,titleSize:14,subtitleSize:11,titleWeight:500,fontFamily:"Inter",foregroundColor:"#dfddd0",mutedColor:"#8e8b7d",highlightColor:"#211e1a",showPinned:false,showIcons:true,showSubtitles:true,showSearchIcon:true,showDivider:true,iconTiles:true,highlightStyle:"soft",highlightOpacity:100,borderOpacity:0,indicatorStyle:"line",indicatorWidth:3,indicatorHeight:50,selectionMotion:"slide",motionDuration:150},{launcherResults:6,launcherFits:false})},
        {id:"original",name:"Impasto",description:"The familiar layout with softly highlighted rows.",values:root.design({})},
        {id:"compact",name:"Compact",description:"A shorter, denser list for a small screen.",values:root.design({width:440,height:360,rowHeight:38,iconSize:26,titleSize:13,subtitleSize:10,padding:14,rowPadding:10,rowVerticalPadding:4,gap:9,rowRadius:7},{launcherResults:7})},
        {id:"spotlight",name:"Spotlight",description:"Large icons and comfortable typography in a wide panel.",values:root.design({width:680,height:540,fieldHeight:48,searchSize:23,searchIconSize:22,rowHeight:60,iconSize:42,titleSize:17,subtitleSize:12,cornerRadius:28,rowRadius:15,rowPadding:16,contentGap:16,indicatorStyle:"none",highlightOpacity:15},{launcherResults:7})},
        {id:"minimal",name:"Minimal",description:"Names alone, a fine accent line and a compact search field.",values:root.design({width:420,height:380,rowHeight:34,rowVerticalPadding:4,showIcons:false,showSubtitles:false,showPinned:false,showSearchIcon:false,showDivider:false,titleSize:14,rowSpacing:4,highlightStyle:"none",indicatorWidth:2,indicatorHeight:50,cornerRadius:14},{launcherResults:8,launcherFits:true})},
        {id:"outline",name:"Outline",description:"A clean accent border, simple icon tiles and generous spacing.",values:root.design({width:580,height:500,rowHeight:54,rowSpacing:6,rowRadius:12,highlightStyle:"outline",borderOpacity:65,indicatorStyle:"none",iconTiles:false,padding:22},{launcherResults:7})},
        {id:"terminal",name:"Terminal",description:"Monospaced type, tight rows and an immediate selection.",values:root.design({width:560,height:420,fontFamily:"JetBrainsMono Nerd Font",titleSize:13,subtitleSize:10,showSubtitles:false,iconSize:24,rowHeight:34,rowVerticalPadding:4,rowRadius:3,cornerRadius:8,highlightStyle:"accent",highlightOpacity:19,selectionMotion:"snap",indicatorStyle:"dot",indicatorWidth:4,indicatorHeight:30},{launcherResults:9})},
        {id:"soft",name:"Soft cards",description:"Rounded rows with large artwork and a gentle selection glide.",values:root.design({width:620,height:590,rowHeight:64,iconSize:44,iconRadius:13,rowRadius:20,rowSpacing:7,cornerRadius:30,highlightOpacity:18,borderOpacity:9,indicatorStyle:"none",motionDuration:250,contentGap:16},{launcherResults:7})},
        {id:"wide",name:"Wide desk",description:"More room for app descriptions and larger search results.",values:root.design({width:820,height:600,rowHeight:54,iconSize:38,titleSize:16,subtitleSize:12,padding:24,rowPadding:16,searchSize:20,fieldHeight:44,highlightStyle:"accent",highlightOpacity:13,indicatorStyle:"dot",indicatorWidth:5},{launcherResults:9})},
        {id:"focus",name:"Focus",description:"A narrow list with a large search field and quiet text-only rows.",values:root.design({width:400,height:390,searchSize:22,fieldHeight:50,rowHeight:36,rowSpacing:5,showIcons:false,showSubtitles:false,showPinned:false,indicatorStyle:"dot",indicatorWidth:4,highlightOpacity:6,cornerRadius:22},{launcherResults:7,launcherFits:true})},
        {id:"library",name:"Library",description:"A roomy application library with large icon tiles and descriptions.",values:root.design({width:760,height:670,rowHeight:72,iconSize:52,iconRadius:16,titleSize:18,subtitleSize:13,rowRadius:18,rowSpacing:8,padding:26,searchSize:24,fieldHeight:54,highlightStyle:"accent",highlightOpacity:12,indicatorStyle:"none"},{launcherResults:7})},
        {id:"pearl",name:"Pearl",description:"Rounded compact cards with subtle borders and an unhurried glide.",values:root.design({width:460,height:440,rowHeight:50,iconSize:32,rowRadius:18,iconRadius:10,rowSpacing:6,cornerRadius:28,highlightOpacity:9,borderOpacity:15,indicatorStyle:"none",motionDuration:280,padding:18},{launcherResults:6})},
        {id:"outline-mini",name:"Outline Mini",description:"A compact outline design with small icons and crisp typography.",values:root.design({width:430,height:360,rowHeight:38,rowVerticalPadding:3,iconSize:26,titleSize:12,subtitleSize:9,rowRadius:8,rowSpacing:3,highlightStyle:"outline",borderOpacity:70,indicatorStyle:"none",iconTiles:false,cornerRadius:12,padding:14},{launcherResults:7})},
        {id:"code-desk",name:"Code Desk",description:"A spacious monospaced launcher with descriptions and an accent rail.",values:root.design({width:740,height:570,fontFamily:"JetBrainsMono Nerd Font",titleSize:15,subtitleSize:11,iconSize:32,rowHeight:52,rowSpacing:4,rowRadius:6,cornerRadius:14,searchSize:20,fieldHeight:44,highlightStyle:"accent",highlightOpacity:14,indicatorStyle:"line",indicatorWidth:3,motionDuration:120,padding:22},{launcherResults:8})}
,
        {id:"micro",name:"Micro",description:"A tiny text-only launcher with five crisp rows and no extra chrome.",values:root.design({width:320,height:230,padding:10,fieldHeight:28,searchSize:14,rowHeight:28,rowVerticalPadding:3,rowSpacing:2,gap:6,showIcons:false,showSubtitles:false,showPinned:false,showSearchIcon:false,showDivider:false,titleSize:12,rowRadius:5,cornerRadius:12,highlightOpacity:8,indicatorWidth:2,indicatorHeight:45},{launcherResults:5,launcherFits:true})},
        {id:"bare",name:"Bare",description:"A small floating name list with a restrained accent selection.",values:root.design({width:340,height:280,padding:14,fieldHeight:30,searchSize:15,rowHeight:32,rowVerticalPadding:4,rowSpacing:2,gap:7,showIcons:false,showSubtitles:false,showPinned:false,showDivider:false,titleSize:13,highlightStyle:"accent",highlightOpacity:9,indicatorStyle:"none",rowRadius:8,cornerRadius:16},{launcherResults:6,launcherFits:true})},
        {id:"pocket",name:"Pocket",description:"Small icons and single-line names in a pocket-sized panel.",values:root.design({width:350,height:300,padding:12,fieldHeight:30,searchSize:15,rowHeight:34,rowVerticalPadding:4,rowSpacing:3,gap:8,iconSize:24,iconPadding:3,iconRadius:6,showSubtitles:false,showPinned:false,showDivider:false,titleSize:12,rowRadius:9,cornerRadius:18,indicatorStyle:"none",highlightOpacity:11},{launcherResults:6})},
        {id:"quiet",name:"Quiet",description:"A low-contrast compact list with small bare icons and a fine accent dot.",values:root.design({width:370,height:310,padding:14,fieldHeight:32,searchSize:15,rowHeight:34,rowVerticalPadding:4,rowSpacing:4,gap:8,iconSize:22,iconTiles:false,iconPadding:1,showSubtitles:false,showPinned:false,showSearchIcon:false,showDivider:false,titleSize:13,rowRadius:7,cornerRadius:14,highlightOpacity:5,borderOpacity:0,indicatorStyle:"dot",indicatorWidth:3,motionDuration:160},{launcherResults:6,launcherFits:true})},
        {id:"slim-outline",name:"Slim Outline",description:"A slim panel with a delicate outline and uncomplicated single-line rows.",values:root.design({width:330,height:290,padding:12,fieldHeight:30,searchSize:14,rowHeight:32,rowVerticalPadding:3,rowSpacing:3,gap:7,iconSize:20,iconTiles:false,iconPadding:0,showSubtitles:false,showPinned:false,showDivider:false,titleSize:12,highlightStyle:"outline",borderOpacity:35,indicatorStyle:"none",rowRadius:7,cornerRadius:13,motionDuration:140},{launcherResults:6})}
,
        {id:"cinder",name:"Cinder",description:"A small charcoal-grey launcher with text-only rows and a fine accent rail.",values:root.design({surfaceTone:"grey",width:330,height:250,padding:12,fieldHeight:30,rowHeight:30,rowVerticalPadding:3,gap:6,rowSpacing:3,showIcons:false,showSubtitles:false,showPinned:false,showSearchIcon:false,showDivider:false,titleSize:12,searchSize:14,rowRadius:6,cornerRadius:14,highlightOpacity:10,indicatorWidth:2},{launcherResults:5,launcherFits:true})},
        {id:"graphite-mini",name:"Graphite Mini",description:"Dark-grey compact rows with small icons and soft, rounded selection.",values:root.design({surfaceTone:"grey",width:360,height:300,padding:14,fieldHeight:32,rowHeight:34,rowVerticalPadding:4,iconSize:24,iconRadius:6,iconPadding:3,showSubtitles:false,showPinned:false,showDivider:false,titleSize:13,searchSize:15,rowSpacing:3,gap:7,rowRadius:10,cornerRadius:18,indicatorStyle:"none",highlightOpacity:12},{launcherResults:6})},
        {id:"slate",name:"Slate",description:"A wider slate-grey panel with understated icon tiles and short descriptions.",values:root.design({surfaceTone:"grey",width:450,height:390,padding:16,fieldHeight:34,rowHeight:42,rowVerticalPadding:4,iconSize:28,titleSize:13,subtitleSize:10,searchSize:16,rowSpacing:4,rowRadius:11,cornerRadius:20,highlightOpacity:10,indicatorStyle:"dot",indicatorWidth:3},{launcherResults:7})}

    ]
    readonly property var designs:root.builtins.filter(p=>!(store.hidden||[]).includes(p.id)).map(p=>Object.assign({},p,store.overrides?.[p.id]||{}))
    function rowHeightFor(c:var):int{return Math.ceil(Math.max(c.rowHeight,c.showIcons?c.iconSize+2*c.rowVerticalPadding:0,(c.titleSize+(c.showSubtitles?c.subtitleSize+c.textGap:0))*1.2+2*c.rowVerticalPadding))}
    readonly property var categories:[{id:"compact",name:"Compact"},{id:"balanced",name:"Balanced"},{id:"expanded",name:"Expanded"}]
    readonly property var subcategories:[{id:"classic",name:"Classic"},{id:"minimal",name:"Minimal"},{id:"cards",name:"Cards"},{id:"outline",name:"Outline"},{id:"monospace",name:"Monospace"}]
    function categoryOf(values:var):string{const c=Object.assign({},root.defaults,values.launcherStyle||{});return c.width>=650||c.rowHeight>=60?"expanded":c.width<=460||c.rowHeight<=38?"compact":"balanced"}
    function subcategoryOf(values:var):string{const c=Object.assign({},root.defaults,values.launcherStyle||{});return /mono/i.test(c.fontFamily)?"monospace":c.highlightStyle==="outline"?"outline":!c.showIcons||!c.showSubtitles?"minimal":c.rowRadius>=15?"cards":"classic"}
    function select(items:var,category:string,subcategory:string):var{return items.filter(p=>(category==="all"||root.categoryOf(p.values)===category)&&(subcategory==="all"||root.subcategoryOf(p.values)===subcategory))}
    function setStyle(key:string,value:var):void {
        SettingsService.set("launcherStyle",Object.assign({},SettingsService.launcherStyle||{},{[key]:value}))
        if(key==="cornerRadius"){
            const next=SettingsService.copy(SettingsService.moduleRounding)||{};next.launcher=value;SettingsService.set("moduleRounding",next)
        }
        if(key==="padding"){
            const next=SettingsService.copy(SettingsService.moduleAppearance)||{};if(next.launcher){delete next.launcher.padding;SettingsService.set("moduleAppearance",next)}
        }
    }
    function design(style:var,settings:var):var{const result=Object.assign({launcherResults:9,launcherFits:false,launcherOrder:"recent",elements:{},appearance:{}},settings||{});result.launcherStyle=Object.assign({},root.defaults,style||{});return result}
    function capture():var{return {launcherStyle:SettingsService.copy(root.style),launcherResults:SettingsService.launcherResults,launcherFits:SettingsService.launcherFits,launcherOrder:SettingsService.launcherOrder,elements:SettingsService.copy(SettingsService.moduleElements.launcher)||{},appearance:SettingsService.copy(SettingsService.moduleAppearance.launcher)||{}}}
    function matches(values:var):bool{const a=root.capture(),b=root.design(values.launcherStyle,values);return ["launcherStyle","launcherResults","launcherFits","launcherOrder","elements","appearance"].every(key=>JSON.stringify(a[key])===JSON.stringify(b[key]))}
    function assign(values:var):void {
        const next=root.design(values.launcherStyle,values)
        for(const key of ["launcherStyle","launcherResults","launcherFits","launcherOrder"])SettingsService.set(key,next[key])
        for(const pair of [["moduleElements","elements"],["moduleAppearance","appearance"]]){
            const map=SettingsService.copy(SettingsService[pair[0]])||{}
            if(Object.keys(next[pair[1]]||{}).length)map.launcher=SettingsService.copy(next[pair[1]])
            else delete map.launcher
            SettingsService.set(pair[0],map)
        }
        const radius=SettingsService.copy(SettingsService.moduleRounding)||{};radius.launcher=next.launcherStyle.cornerRadius;SettingsService.set("moduleRounding",radius)
    }
    function apply(values:var):void{if(!SettingsService.arrived)return;previous=root.capture();root.assign(values)}
    function undo():void{if(previous){const old=previous;previous=null;root.assign(old)}}
    function save(name:string):string {
        if(!ready||!SettingsService.arrived)return ""
        const clean=(name||"My launcher").trim().slice(0,40)||"My launcher"
        let label=clean;for(let i=2;root.saved.some(p=>p.name===label);i++)label=clean+" "+i
        const id="launcher-"+Date.now()+"-"+Math.random().toString(36).slice(2,7)
        store.presets=root.saved.concat([{id,name:label,values:root.capture()}]);return id
    }
    function update(id:string):void {
        if(root.builtins.some(p=>p.id===id))store.overrides=Object.assign({},store.overrides||{},{[id]:{values:root.capture()}})
        else store.presets=root.saved.map(p=>p.id===id?Object.assign({},p,{values:root.capture()}):p)
    }
    function remove(id:string):void{if(root.builtins.some(p=>p.id===id))store.hidden=[...(store.hidden||[]),id];else store.presets=root.saved.filter(p=>p.id!==id)}
    function restore():void{store.hidden=[];store.overrides={}}
    function seed():void{if(root.ready&&SettingsService.arrived&&!store.initialized){store.initialized=true;root.save("My original launcher")}}
    readonly property Connections settingsReady:Connections{target:SettingsService;function onArrivedChanged(){root.seed()}}
    readonly property FileView file:FileView{
        path:SettingsService.stateDirectory+"/launcher-presets.json"
        watchChanges:true
        onFileChanged:reload()
        onLoaded:{root.ready=true;root.seed()}
        onLoadFailed:error=>{if(error===FileViewError.FileNotFound){root.ready=true;root.seed()}}
        onAdapterUpdated:if(root.ready)saver.restart()
        readonly property Timer saver:Timer{interval:0;onTriggered:root.file.writeAdapter()}
        JsonAdapter{id:store;property bool initialized:false;property var presets:[];property var overrides:({});property var hidden:[]}
    }
}
