pragma Singleton

import QtQuick
import Quickshell.Io

// Island-only snapshots live separately from full desktop profiles.
QtObject {
    id: root

    property bool ready: false
    property bool applying:false
    property var beforePresentation:({})
    readonly property var presentation:root.applying ? root.beforePresentation : SettingsService
    function freezePresentation():void {
        const before={}
        for(const key of root.keys.concat(root.geometryKeys))before[key]=SettingsService[key]
        root.beforePresentation=Object.assign(SettingsService.copy(before),{
            notched:SettingsService.notched,islandSummary:SettingsService.islandSummary,islandSummaryMode:SettingsService.islandSummaryMode})
    }
    property int lastApplyMs:0
    property var lastApplyProfile:({})
    property int appliedRevision:0
    readonly property string activePresetId:store.activePresetId
    function rememberActive(id:string):void{if(root.ready && store.activePresetId!==id)store.activePresetId=id}
    function activeEntry():var {
        const library=root.saved.concat(root.designs)
        if(root.applying)return library.find(item=>item.id===store.activePresetId)||null
        const now=root.capture()
        return library.find(item=>root.keys.every(key=>JSON.stringify(now[key])===JSON.stringify(item.values[key]===undefined?SettingsService.pristine[key]:item.values[key])) && JSON.stringify(now.barElementLayout)===JSON.stringify(item.values.barElementLayout||{}) && JSON.stringify(now.barStyleOverrides)===JSON.stringify(item.values.barStyleOverrides||{}) && root.geometryMatches(now,item.values))
            ||library.find(item=>item.id===store.activePresetId)||null
    }
    property var previous: null
    property string previousBarStyle: ""
    readonly property var saved: SettingsService.copy(store.presets) ?? []
    // Calendar/media interaction is a global preference, never a bar design.
    readonly property var keys: SettingsService.profileKeys.filter(key =>
        (key.startsWith("island") || key.startsWith("clock"))
        && !["islandSummary", "islandSummaryMode"].includes(key))

    function captureBarStyle():var {
        const style={}
        if(Object.keys(SettingsService.moduleAppearance.bar||{}).length)style.appearance=SettingsService.copy(SettingsService.moduleAppearance.bar)
        if(typeof SettingsService.moduleRounding.bar==="number")style.rounding=SettingsService.moduleRounding.bar
        return style
    }
    readonly property var geometryKeys:["barStyle","barShadow","barShadowRange","barShadowIntensity","barShadowSharpness","barShadowOffsetX","barShadowOffsetY","barShadowUseAccent","barSideMargin","barScale","barHeight","barMargin","notchCornerRadius","notchRoundingPower","notchShoulderRoundingPower","workspaceInactiveBrightness","workspaceOccupiedBrightness","notchShoulderRadius","notchOffsetX","workspaceStyle","workspaceCount","workspaceDimensions","workspaceGlowRange","workspaceGlowIntensity","workspaceGlowSpread"]
    function capture(): var {
        const result = {}
        for (const key of root.keys)
            result[key] = SettingsService[key]
        result.barElementLayout=SettingsService.copy(SettingsService.moduleElements.bar)||{}
        result.barStyleOverrides=root.captureBarStyle()
        result.barGeometry={};for(const key of root.geometryKeys)result.barGeometry[key]=SettingsService.copy(SettingsService[key])
        return SettingsService.copy(result)
    }

    function complete(values: var): var {
        const given=values||{}
        const result={}
        for(const key of root.keys) {
            const valid=Object.prototype.hasOwnProperty.call(given,key)&&SettingsService.accepts(key,given[key])
            result[key]=SettingsService.copy(valid?given[key]:SettingsService.pristine[key])
        }
        result.barElementLayout=SettingsService.copy(values?.barElementLayout)||{}
        result.barStyleOverrides=SettingsService.copy(values?.barStyleOverrides)||{}
        result.barGeometry=SettingsService.copy(values?.barGeometry)||{}
        return result
    }

    function design(overrides: var): var {
        return root.complete(Object.assign({
            islandPillWidth: 260, islandPaddingLeft: 16, islandPaddingRight: 16,
            islandClockSize: 19, islandLayout: "balanced", islandAttached: true,
            islandActivities: ["privacy", "timer", "media", "machine"],
            islandActivitiesSeen: SettingsService.besideChoices.slice()
        }, overrides))
    }

    readonly property var builtins: [
        {id:"reference-notch",name:"Reference Notch",subcategory:"compact",description:"Measured reference layout: 242 × 32px notch, five upright workspaces, 16px clock, signal and reference battery. Keeps your theme colours.",values:root.design({
            islandPillWidth:203,islandPaddingLeft:24,islandPaddingRight:15,islandAttached:true,islandChipsEnabled:false,
            islandClockSize:16,islandLayout:"balanced",clockFormat:"HH:mm",clockShowsDate:false,clockShowsSeconds:false,
            islandWorkspaces:true,islandWorkspacesPosition:"left",islandWorkspacesScale:100,islandWorkspacesOffset:0,islandWorkspacesGlow:true,
            islandInternet:true,islandInternetStyle:"bars",islandInternetPosition:"right",islandInternetScale:100,islandInternetOffset:6,
            islandBattery:true,islandBatteryMode:"icon",islandBatteryIconStyle:"reference",islandBatteryPosition:"right",islandBatteryScale:100,islandBatteryOffset:-2,
            islandBluetooth:false,islandSpeaker:false,islandActivities:[],islandActivitiesSeen:SettingsService.besideChoices.slice(),
            barElementLayout:{"design:ClockModule:1":{y:-1},"design:ClockModule:6":{fontFamily:"Inter",fontSize:16}},barStyleOverrides:{rounding:14},
            barGeometry:{barStyle:"grouped",barScale:100,barHeight:32,barMargin:0,notchCornerRadius:14,notchRoundingPower:2,notchShoulderRoundingPower:2,workspaceInactiveBrightness:100,workspaceOccupiedBrightness:100,notchShoulderRadius:6,notchOffsetX:-2,
                workspaceStyle:"dots",workspaceCount:5,workspaceDimensions:{dots:{width:6,height:10,activeWidth:8,activeHeight:14,inactiveWidth:6,inactiveHeight:10,spacing:5}},workspaceGlowRange:14,workspaceGlowIntensity:55,workspaceGlowSpread:115}
        })},

        { id: "compact", name: "Compact", description: "A small clock with Wi-Fi and battery.",
          values: root.design({ islandPillWidth: 190, islandClockSize: 18,
              islandBattery: true, islandBatteryMode: "icon", islandInternet: true,
              islandInternetStyle: "wifi", islandLayout: "compact" }) },
        { id: "balanced", name: "Everyday", description: "Workspaces left, time centered, status right.",
          values: root.design({ islandPillWidth: 290, islandWorkspaces: true,
              islandWorkspacesGlow: true, islandInternet: true, islandInternetStyle: "wifi",
              islandBattery: true, islandBatteryMode: "both", islandClockSize: 20 }) },
        { id: "floating", name: "Floating", description: "A floating clock and date with a quiet status row.",
          values: root.design({ islandAttached: false, islandPillWidth: 310,
              clockShowsDate: true, islandBattery: true, islandBatteryMode: "icon",
              islandInternet: true, islandInternetStyle: "bars", islandLayout: "compact" }) },
        { id: "connected", name: "Connected", description: "Workspaces, Wi-Fi, Bluetooth, volume and battery.",
          values: root.design({ islandPillWidth: 390, islandWorkspaces: true,
              islandInternet: true, islandInternetStyle: "wifi", islandBluetooth: true,
              islandSpeaker: true, islandSpeakerPercent: true,
              islandBattery: true, islandBatteryMode: "both" }) },
        { id: "zen", name: "Zen", description: "A small floating capsule with a large clock and no status clutter.",
          values: root.design({ islandAttached: false, islandPillWidth: 126,
              islandPaddingLeft: 18, islandPaddingRight: 18, islandClockSize: 26,
              clockFormat: "HH:mm", clockShowsDate: false, clockShowsSeconds: false,
              islandLayout: "balanced", islandActivities: ["privacy"] }) },
        { id: "studio", name: "Studio", description: "Volume and Bluetooth on the left, a centered clock and a quiet battery icon.",
          values: root.design({ islandAttached: false, islandPillWidth: 336,
              islandPaddingLeft: 20, islandPaddingRight: 22, islandClockSize: 19,
              clockFormat: "HH:mm", islandLayout: "balanced",
              islandSpeaker: true, islandSpeakerPercent: true,
              islandSpeakerPosition: "left", islandSpeakerScale: 110, islandSpeakerOffset: 2,
              islandBluetooth: true, islandBluetoothPosition: "left",
              islandBluetoothScale: 90, islandBluetoothOffset: 2,
              islandBattery: true, islandBatteryMode: "icon", islandBatteryScale: 90,
              islandBatteryPosition: "right", islandBatteryOffset: -2,
              islandActivities: ["privacy", "media"] }) },
        { id: "metro", name: "Metro", description: "A bold clock with seconds, enlarged signal bars and battery percentage inside the icon.",
          values: root.design({ islandAttached: true, islandPillWidth: 246,
              islandPaddingLeft: 22, islandPaddingRight: 22, islandClockSize: 24,
              clockFormat: "HH:mm", clockShowsSeconds: true, clockShowsDate: false,
              islandLayout: "balanced", islandInternet: true, islandInternetStyle: "bars",
              islandInternetPosition: "left", islandInternetScale: 125,
              islandBattery: true, islandBatteryMode: "both", islandBatteryPosition: "right",
              islandBatteryScale: 110, islandActivities: ["privacy", "timer"] }) },
        { id: "horizon", name: "Horizon", description: "An airy floating island with a 12-hour clock, date, small workspaces and discreet status.",
          values: root.design({ islandAttached: false, islandPillWidth: 450,
              islandPaddingLeft: 24, islandPaddingRight: 24, islandClockSize: 18,
              clockFormat: "hh:mm AP", clockShowsDate: true, clockShowsSeconds: false,
              islandLayout: "balanced", islandWorkspaces: true,
              islandWorkspacesPosition: "left", islandWorkspacesScale: 80,
              islandWorkspacesGlow: false, islandWorkspacesOffset: 3,
              islandInternet: true, islandInternetStyle: "wifi", islandInternetPosition: "right",
              islandInternetScale: 90, islandInternetOffset: -3,
              islandBattery: true, islandBatteryMode: "percent", islandBatteryPosition: "right",
              islandBatteryScale: 90, islandBatteryOffset: -3,
              islandActivities: ["privacy", "timer", "media"] }) },
        { id: "mirror", name: "Mirror", description: "Wi-Fi and battery on the left, time in the center and glowing workspaces on the right.",
          values: root.design({ islandAttached: true, islandPillWidth: 330,
              islandPaddingLeft: 22, islandPaddingRight: 22, islandClockSize: 21,
              clockFormat: "HH:mm", islandLayout: "balanced",
              islandInternet: true, islandInternetStyle: "wifi", islandInternetPosition: "left",
              islandInternetScale: 105, islandInternetOffset: 2,
              islandBattery: true, islandBatteryMode: "both", islandBatteryPosition: "left",
              islandBatteryScale: 95, islandBatteryOffset: 2,
              islandWorkspaces: true, islandWorkspacesPosition: "right",
              islandWorkspacesScale: 110, islandWorkspacesGlow: true, islandWorkspacesOffset: -2,
              islandActivities: ["privacy", "timer", "media", "machine"] }) },
        { id: "orbit-mini", name: "Orbit Mini", description: "Separate artwork and Wi-Fi circles around a compact clock.",
          values: root.design({islandChipsEnabled:true,islandAttached:false,islandPillWidth:80,islandClockSize:18,islandChipGap:12,
            islandActivities:["privacy","timer"],islandChipSettings:{
              clock:{width:96,height:34,style:"pill",surface:"solid"},
              media:{enabled:true,side:"left",order:0,width:34,height:34,style:"circle",display:"artwork"},
              internet:{enabled:true,side:"right",order:0,width:34,height:34,style:"circle",display:"ring"}
            }}) },
        { id: "daily-chips", name: "Daily Chips", description: "Workspaces and artwork on the left; Wi-Fi and battery on the right.",
          values: root.design({islandChipsEnabled:true,islandAttached:false,islandPillWidth:90,islandClockSize:20,islandChipGap:10,
            islandActivities:["privacy","timer"],islandChipSettings:{
              clock:{width:112,height:38,style:"pill"},
              workspaces:{enabled:true,side:"left",order:0,width:112,height:36,style:"pill"},
              media:{enabled:true,side:"left",order:1,width:38,height:38,style:"circle",display:"artwork"},
              internet:{enabled:true,side:"right",order:0,width:36,height:36,style:"circle",display:"icon"},
              battery:{enabled:true,side:"right",order:1,width:52,height:36,style:"pill",display:"both"}
            }}) },
        { id: "studio-chips", name: "Studio Chips", description: "A separate media control pill, centered time, Wi-Fi and battery chips.",
          values: root.design({islandChipsEnabled:true,islandAttached:false,islandPillWidth:90,islandClockSize:19,islandChipGap:12,
            islandActivities:["privacy","timer"],islandChipSettings:{
              clock:{width:108,height:36,style:"pill"},
              media:{enabled:true,side:"left",order:0,width:150,height:36,style:"pill",display:"controls"},
              internet:{enabled:true,side:"right",order:0,width:36,height:36,style:"circle",display:"ring"},
              battery:{enabled:true,side:"right",order:1,width:54,height:36,style:"pill",display:"both"}
            }}) }
        ,{id:"pebble",name:"Pebble",subcategory:"compact",description:"A compact floating clock with quiet Wi-Fi and battery icons.",
          values:root.design({islandAttached:false,islandPillWidth:170,islandClockSize:19,islandPaddingLeft:12,islandPaddingRight:12,islandInternet:true,islandInternetStyle:"wifi",islandBattery:true,islandBatteryMode:"icon"})}
        ,{id:"quiet",name:"Quiet",subcategory:"minimal",description:"A softly spaced floating clock, with everything else tucked away.",
          values:root.design({islandAttached:false,islandPillWidth:140,islandClockSize:22,islandPaddingLeft:12,islandPaddingRight:12,islandActivities:["privacy"],})}
        ,{id:"still",name:"Still",subcategory:"minimal",description:"An attached clock-only notch with restrained proportions.",
          values:root.design({islandAttached:true,islandPillWidth:130,islandClockSize:20,islandPaddingLeft:14,islandPaddingRight:14,islandActivities:["privacy"]})}
        ,{id:"focus",name:"Focus",subcategory:"minimal",description:"A slim notch with small workspace dots beside the clock.",
          values:root.design({islandAttached:true,islandPillWidth:180,islandClockSize:19,islandWorkspaces:true,islandWorkspacesScale:65,islandWorkspacesPosition:"left",islandPaddingLeft:12,islandPaddingRight:12,islandActivities:["privacy","timer"]})}
        ,{id:"pocket-chips",name:"Pocket Chips",subcategory:"compact",description:"Small separate Wi-Fi and battery circles around a compact time pill.",
          values:root.design({islandChipsEnabled:true,islandAttached:false,islandPillWidth:80,islandClockSize:18,islandChipGap:8,islandActivities:["privacy","timer"],islandChipSettings:{clock:{width:88,height:32,style:"pill"},internet:{enabled:true,side:"left",order:0,width:30,height:30,style:"circle",display:"ring"},battery:{enabled:true,side:"right",order:0,width:30,height:30,style:"circle",display:"ring"}}})}
        ,{id:"bare-chips",name:"Bare Chips",subcategory:"minimal",description:"Just the time and a discreet workspace chip.",
          values:root.design({islandChipsEnabled:true,islandAttached:false,islandPillWidth:76,islandClockSize:18,islandChipGap:7,islandActivities:["privacy"],islandChipSettings:{clock:{width:82,height:30,style:"pill"},workspaces:{enabled:true,side:"left",order:0,width:62,height:28,style:"pill",iconScale:65}}})}
        ,{id:"mono-chips",name:"Mono Chips",subcategory:"minimal",description:"A clean clock pill and one small battery circle.",
          values:root.design({islandChipsEnabled:true,islandAttached:false,islandPillWidth:80,islandClockSize:19,islandChipGap:8,islandActivities:["privacy"],islandChipSettings:{clock:{width:86,height:32,style:"pill"},battery:{enabled:true,side:"right",order:0,width:30,height:30,style:"circle",display:"ring"}}})}
        ,{id:"aster",name:"Aster",subcategory:"minimal",description:"A quiet floating clock and a small battery icon, with balanced breathing room.",
          values:root.design({islandAttached:false,islandChipsEnabled:false,islandPillWidth:136,islandPaddingLeft:14,islandPaddingRight:14,islandFloatingGap:14,islandClockSize:21,clockFormat:"HH:mm",clockShowsDate:false,clockShowsSeconds:false,islandLayout:"balanced",islandWorkspaces:false,islandInternet:false,islandBluetooth:false,islandSpeaker:false,islandBattery:true,islandBatteryMode:"icon",islandBatteryScale:85,islandBatteryPosition:"right",islandActivities:["privacy"]})}
        ,{id:"linen",name:"Linen",subcategory:"compact",description:"A clean floating status capsule with a centered clock, discreet Wi-Fi and battery percentage.",
          values:root.design({islandAttached:false,islandChipsEnabled:false,islandPillWidth:216,islandPaddingLeft:16,islandPaddingRight:16,islandFloatingGap:16,islandClockSize:19,clockFormat:"HH:mm",clockShowsDate:false,clockShowsSeconds:false,islandLayout:"balanced",islandWorkspaces:false,islandBluetooth:false,islandSpeaker:false,islandInternet:true,islandInternetStyle:"wifi",islandInternetPosition:"left",islandInternetScale:85,islandBattery:true,islandBatteryMode:"percent",islandBatteryPosition:"right",islandBatteryScale:90,islandActivities:["privacy","timer"]})}
        ,{id:"pin",name:"Pin",subcategory:"minimal",description:"A small clock-only notch with even side spacing and no visual clutter.",
          values:root.design({islandAttached:true,islandChipsEnabled:false,islandPillWidth:112,islandPaddingLeft:14,islandPaddingRight:14,islandClockSize:20,clockFormat:"HH:mm",clockShowsDate:false,clockShowsSeconds:false,islandLayout:"balanced",islandWorkspaces:false,islandInternet:false,islandBluetooth:false,islandSpeaker:false,islandBattery:false,islandActivities:["privacy"]})}
        ,{id:"cove",name:"Cove",subcategory:"compact",description:"A restrained notch with subtle Wi-Fi and battery icons around the time.",
          values:root.design({islandAttached:true,islandChipsEnabled:false,islandPillWidth:184,islandPaddingLeft:14,islandPaddingRight:14,islandClockSize:20,clockFormat:"HH:mm",clockShowsDate:false,clockShowsSeconds:false,islandLayout:"balanced",islandWorkspaces:false,islandBluetooth:false,islandSpeaker:false,islandInternet:true,islandInternetStyle:"wifi",islandInternetPosition:"left",islandInternetScale:90,islandBattery:true,islandBatteryMode:"icon",islandBatteryPosition:"right",islandBatteryScale:90,islandActivities:["privacy","timer"]})}
        ,{id:"halo",name:"Halo",subcategory:"minimal",description:"An airy time capsule and a small battery ring that follows your theme.",
          values:root.design({islandAttached:false,islandChipsEnabled:true,islandPillWidth:106,islandPaddingLeft:0,islandPaddingRight:0,islandFloatingGap:16,islandClockSize:20,clockFormat:"HH:mm",clockShowsDate:false,clockShowsSeconds:false,islandChipGap:10,islandWorkspaces:false,islandInternet:false,islandBluetooth:false,islandSpeaker:false,islandBattery:true,islandActivities:["privacy"],islandChipSettings:{clock:{width:106,height:36,style:"pill",surface:"theme"},media:{enabled:false},workspaces:{enabled:false},internet:{enabled:false},bluetooth:{enabled:false},speaker:{enabled:false},battery:{enabled:true,side:"right",order:0,width:32,height:32,style:"circle",surface:"theme",display:"ring"}}})}
        ,{id:"sparrow",name:"Sparrow",subcategory:"compact",description:"Small workspace, Wi-Fi and battery chips framing a tidy central clock.",
          values:root.design({islandAttached:false,islandChipsEnabled:true,islandPillWidth:96,islandPaddingLeft:0,islandPaddingRight:0,islandFloatingGap:14,islandClockSize:19,clockFormat:"HH:mm",clockShowsDate:false,clockShowsSeconds:false,islandChipGap:9,islandWorkspaces:true,islandInternet:true,islandBluetooth:false,islandSpeaker:false,islandBattery:true,islandActivities:["privacy","timer"],islandChipSettings:{clock:{width:96,height:34,style:"pill",surface:"theme"},media:{enabled:false},workspaces:{enabled:true,side:"left",order:0,width:76,height:30,style:"pill",surface:"theme",iconScale:70},internet:{enabled:true,side:"right",order:0,width:30,height:30,style:"circle",surface:"theme",display:"ring"},bluetooth:{enabled:false},speaker:{enabled:false},battery:{enabled:true,side:"right",order:1,width:46,height:30,style:"pill",surface:"theme",display:"icon",iconScale:90}}})}
    ]

    readonly property var designs: root.builtins.filter(item=>!(store.hiddenDesigns||[]).includes(item.id))
        .map(item=>Object.assign({},item,store.designOverrides?.[item.id]||{}))
    function restoreDesigns(): void { store.hiddenDesigns=[];store.designOverrides=({}) }

    readonly property var categories: [
        {id:"floating",name:"Floating"}, {id:"notched",name:"Notched"}, {id:"chips",name:"Chips"}
    ]
    readonly property var subcategories: [
        {id:"compact",name:"Compact"}, {id:"minimal",name:"Minimal"}, {id:"expanded",name:"Expanded"}
    ]
    function categoryOf(values: var): string {
        return values.islandChipsEnabled ? "chips" : values.islandAttached ? "notched" : "floating"
    }
    function subcategoryOf(preset: var): string {
        if (preset.subcategory) return preset.subcategory
        const known = {compact:"compact", balanced:"expanded", floating:"compact", connected:"expanded",
            zen:"minimal", studio:"expanded", metro:"compact", horizon:"expanded", mirror:"expanded",
            "orbit-mini":"compact", "daily-chips":"expanded", "studio-chips":"expanded"}
        if (known[preset.id]) return known[preset.id]
        const v=preset.values
        const count=v.islandChipsEnabled
            ? Object.entries(v.islandChipSettings || {}).filter(([key,chip]) => key!=="clock" && chip.enabled).length
            : [v.islandWorkspaces,v.islandInternet,v.islandBattery,v.islandBluetooth,v.islandSpeaker].filter(Boolean).length
        return count<=1 && v.islandPillWidth<=180 ? "minimal" : count<=3 && v.islandPillWidth<=320 ? "compact" : "expanded"
    }
    function select(items: var, category: string, subcategory: string): var {
        return items.filter(item => root.categoryOf(item.values)===category
            && (subcategory==="all" || root.subcategoryOf(item)===subcategory))
    }

    function geometryMatches(now:var,values:var):bool {
        const wanted=values.barGeometry||{}
        if(!root.geometryKeys.every(key=>wanted[key]===undefined||JSON.stringify(now.barGeometry[key])===JSON.stringify(wanted[key])))return false
        return wanted.notchRoundingPower===undefined||wanted.notchShoulderRoundingPower!==undefined||now.barGeometry.notchShoulderRoundingPower===wanted.notchRoundingPower
    }
    function matches(values: var): bool {
        if(root.applying)return false
        if (!SettingsService.arrived)
            return false
        const now = root.capture()
        const wanted = root.complete(values)
        return root.keys.every(key => JSON.stringify(now[key]) === JSON.stringify(wanted[key])) && JSON.stringify(now.barElementLayout)===JSON.stringify(wanted.barElementLayout) && JSON.stringify(now.barStyleOverrides)===JSON.stringify(wanted.barStyleOverrides) && root.geometryMatches(now,wanted)
    }

    function clearBarOverrides():void {
        for(const name of ["moduleElements","moduleAppearance","moduleRounding"]){
            const next=SettingsService.copy(SettingsService[name])||{}
            if(next.bar!==undefined){delete next.bar;SettingsService.set(name,next)}
        }
    }
    property var layoutCosts:[]
    function layoutSet(key:string,value:var):void {const at=Date.now();SettingsService.set(key,value);const ms=Date.now()-at;if(root.applying&&ms)root.layoutCosts.push({key,ms})}
    function restoreBarLayout(values:var):void {
        for(const key of root.geometryKeys)if(values.barGeometry?.[key]!==undefined)root.layoutSet(key,SettingsService.copy(values.barGeometry[key]))
        if(values.barGeometry?.notchRoundingPower!==undefined&&values.barGeometry?.notchShoulderRoundingPower===undefined)
            root.layoutSet("notchShoulderRoundingPower",values.barGeometry.notchRoundingPower)
        const next=SettingsService.copy(SettingsService.moduleElements)||{}
        if(Object.keys(values.barElementLayout||{}).length)next.bar=SettingsService.copy(values.barElementLayout)
        else delete next.bar
        root.layoutSet("moduleElements",next)
        const appearance=SettingsService.copy(SettingsService.moduleAppearance)||{}
        const rounding=SettingsService.copy(SettingsService.moduleRounding)||{}
        if(values.barStyleOverrides?.appearance)appearance.bar=SettingsService.copy(values.barStyleOverrides.appearance)
        else delete appearance.bar
        if(typeof values.barStyleOverrides?.rounding==="number")rounding.bar=values.barStyleOverrides.rounding
        else delete rounding.bar
        root.layoutSet("moduleAppearance",appearance)
        root.layoutSet("moduleRounding",rounding)
    }
    function apply(values: var, knownId:var): bool {
        if (!root.ready || !SettingsService.arrived)return false
        const began=Date.now()
        const stats={},sets=[];root.layoutCosts=[]
        let mark=Date.now()
        root.previous=root.capture()
        stats.capture=Date.now()-mark;mark=Date.now()
        root.previousBarStyle=SettingsService.barStyle
        const next=root.complete(values)
        stats.complete=Date.now()-mark;mark=Date.now()
        root.freezePresentation()
        stats.freeze=Date.now()-mark;mark=Date.now()
        root.applying=true
        stats.hold=Date.now()-mark;mark=Date.now()
        try {
            if ((next.islandChipsEnabled && ["bezel","island"].includes(SettingsService.barStyle))
                    || (!next.islandAttached && SettingsService.barStyle === "bezel"))SettingsService.set("barStyle","grouped")
            for(const key of root.keys){const at=Date.now();SettingsService.set(key,next[key]);const ms=Date.now()-at;if(ms)sets.push({key,ms})}
            stats.settings=Date.now()-mark;mark=Date.now()
            root.restoreBarLayout(next)
            stats.layout=Date.now()-mark;mark=Date.now()
        } finally {root.applying=false;stats.release=Date.now()-mark;mark=Date.now()}
        const id=typeof knownId==="string"&&knownId?knownId:root.activeEntry()?.id
        if(id&&store.activePresetId!==id)store.activePresetId=id
        root.appliedRevision++
        root.lastApplyMs=Date.now()-began
        stats.total=root.lastApplyMs;stats.sets=sets;stats.layoutSets=root.layoutCosts;root.lastApplyProfile=stats
        return true
    }

    function undo(): void {
        if (!root.previous || !SettingsService.arrived)
            return
        const values = root.previous
        root.previous = null
        root.freezePresentation()
        root.applying=true
        try {
            if (root.previousBarStyle) SettingsService.set("barStyle",root.previousBarStyle)
            for(const key of root.keys)SettingsService.set(key,values[key])
            root.restoreBarLayout(values)
        } finally {root.applying=false}
        root.appliedRevision++
    }

    function save(name: string): string {
        if (!root.ready || !SettingsService.arrived)
            return ""
        const clean = name.replace(/\s+/g, " ").trim().slice(0, 40) || "My island"
        const taken = new Set(root.saved.map(item => item.name.toLowerCase()))
        let unique = clean
        for (let n = 2; taken.has(unique.toLowerCase()); n++)
            unique = `${clean} ${n}`
        const id = `island-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
        store.presets = root.saved.concat([{ id, name: unique, values: root.capture() }])
        return id
    }

    function update(id: string): void {
        if (!root.ready || !SettingsService.arrived)
            return
        const values = root.capture()
        if (root.builtins.some(item=>item.id===id)) {
            store.designOverrides=Object.assign({},store.designOverrides||{}, {[id]:{values}})
            return
        }
        store.presets = root.saved.map(item => item.id === id
            ? Object.assign({}, item, { values }) : item)
    }

    function remove(id: string): void {
        if (!root.ready) return
        if (root.builtins.some(item=>item.id===id)) {
            store.hiddenDesigns=[...(store.hiddenDesigns||[]),id]
            return
        }
        store.presets=root.saved.filter(item=>item.id!==id)
    }

    function seed(): void {
        if (!root.ready || !SettingsService.arrived || store.initialized)
            return
        store.initialized = true
        root.save("My current island")
    }

    readonly property Connections settingsReady: Connections {
        target: SettingsService
        function onArrivedChanged(): void { root.seed() }
    }

    readonly property IpcHandler referenceApi:IpcHandler {
        target:"bar-preset"
        function apply(id:string):bool {const p=root.designs.concat(root.saved).find(p=>p.id===id);return p?root.apply(p.values,p.id):false}
        function save(name:string):string {return root.save(name)}
        function status():string {return JSON.stringify({active:root.activePresetId,width:ModuleService.restWidth,lastApplyMs:root.lastApplyMs,profile:root.lastApplyProfile,presets:root.designs.map(p=>({id:p.id,name:p.name}))})}
    }
    readonly property FileView file: FileView {
        path: `${SettingsService.stateDirectory}/island-presets.json`
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: { if (root.ready) saver.restart() }
        onLoaded: { root.ready = true; root.seed() }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.ready = true
                root.seed()
            }
        }
        readonly property Timer saver: Timer {
            interval: 0
            onTriggered: root.file.writeAdapter()
        }
        JsonAdapter {
            id: store
            property int schema: 1
            property string activePresetId:""
            property bool initialized: false
            property var presets: []
            property var hiddenDesigns: []
            property var designOverrides: ({})
        }
    }
}
