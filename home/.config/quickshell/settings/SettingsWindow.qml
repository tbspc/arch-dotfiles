import "../" as Config
// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E T T I N G S   W I N D O W                                          │
// │   settings window · a regular, movable window                            │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import "StudioBridge.js" as StudioBridge
import Quickshell
import Quickshell.Io

import "../components"
import "../theme"
import "../services"

// Settings is a window rather than an island panel, so the bar and island stay
// visible and react live while their own settings change.
//
// It is an xdg-shell toplevel, not a layer surface: Hyprland moves, resizes,
// focuses and closes it like any other window, and draws its rounding and
// shadow. `windowrules.lua` floats and sizes it, matched on the title.
FloatingWindow {
    id: root
    readonly property bool settingsPalette: true
    CornerGuard {}

    // Kept in sync with `visible` both ways, so closing the window from the
    // compositor resets it and it can be opened again.
    property bool shown: false

    function open(): void { root.minimized=false; root.shown = true; placementDelay.restart() }
    Timer {id:placementDelay;interval:50;onTriggered:CompositorService.applySettingsWindowMode()}
    function close():void {root.shown=false}
    function toggle(): void { if(root.shown)root.close();else root.open() }

    // Island panels are opened by the shell, not by this window.
    signal panelRequested(string panel)

    // Matched by the window rule in `windowrules.lua`.
    title:"Hyprland Settings"

    implicitWidth:SettingsDesignService.style.windowWidth
    implicitHeight:SettingsDesignService.style.windowHeight


    color:SettingsDesignService.modern?"transparent":SettingsDesignService.style.background||Theme.island
    visible: root.shown

    onVisibleChanged: {
        if (!root.visible && root.shown)
            root.shown = false
    }

    // Built on open and destroyed on close, so pages query state when created
    // and release their subscriptions when gone.
    Loader {
        id: settingsLoader
        anchors.fill: parent
        active: root.visible
        sourceComponent: panel
        onLoaded: {
            if(root.requestedSection)navigationTimer.restart()
        }
    }

    FontLoader {source: "../assets/fonts/Geist.ttf"}
    property string requestedSection:""
    property string requestedTab:""
    Timer {
        id:navigationTimer
        interval:16
        onTriggered:if(settingsLoader.item && settingsLoader.item.sections.some(s=>s.id===root.requestedSection))settingsLoader.item.go(root.requestedSection,root.requestedTab)
    }
    IpcHandler {
        target: "settings"
        function studioSnapshot():string {
            const snapshot=JSON.parse(StudioBridge.snapshot(SettingsService,Theme,ThemeService))
            const same=(value,expected)=>{if(expected&&typeof expected==="object")return Object.keys(expected).every(k=>same(value?.[k],expected[k]));return value===expected}
            const score=value=>value&&typeof value==="object"?Object.keys(value).reduce((n,k)=>n+score(value[k]),0):1
            const presets=Theme.motionPresets.concat(SettingsService.savedShellMotionPresets)
            const matching=presets.filter(p=>SettingsService.motionScale===p.scale&&SettingsService.motionCurve===p.curve&&Object.keys(p.settings||{}).every(k=>same(SettingsService[k],p.settings[k]))).sort((a,b)=>score(b.settings)-score(a.settings))
            snapshot.shellMotionPresets=presets.map(p=>({id:p.id,name:p.label||p.name,note:p.note||((p.scale??100)===0?"Animations disabled":"Shell animation preset"),active:p.id===matching[0]?.id}))
            snapshot.windowMotionPresets=Motion.presets.map(p=>({id:p.id,name:p.label||p.name||p.id,note:p.note||p.description||"Window animation preset",active:SettingsService.animationPreset===p.id}))
            return JSON.stringify(snapshot)
        }
        function studioMotion(kind:string,id:string):string {
            if(kind==="shell"){
                const preset=Theme.motionPresets.concat(SettingsService.savedShellMotionPresets).find(p=>p.id===id)
                if(!preset)return "Unknown shell preset"
                SettingsService.applyShellMotionPreset(preset)
                if(!preset.moduleOverrides)SettingsService.set("moduleAnimations",{all:{followShell:true},bar:{followShell:true},summary:{followShell:true}})
            }else if(kind==="windows"){
                if(!Motion.presets.some(p=>p.id===id))return "Unknown window preset"
                SettingsService.set("animationPreset",id)
            }else return "Unknown animation category"
            return "ok"
        }
        function studioSet(id:string,document:string):string {return StudioBridge.set(SettingsService,id,document)}
        function studioAccent(colour:string):string {
            if(!/^#[0-9a-fA-F]{6}$/.test(colour))return "Use a six-digit hex colour"
            if(!SettingsService.arrived)return "Settings are not ready"
            const colours={};for(const key of Theme.tokens)colours[key]=String(Theme[key==="textMuted"?"paletteMuted":key])
            colours.accent=colour;colours.accentHover=String(Qt.lighter(colour,1.15))
            const existing=SettingsService.savedColourThemes.find(t=>t.id==="saved-colours-sane-custom")
            const entry={id:"saved-colours-sane-custom",name:"Sane Settings · Custom",colors:colours}
            SettingsService.set("savedColourThemes",existing?SettingsService.savedColourThemes.map(t=>t.id===entry.id?entry:t):SettingsService.savedColourThemes.concat([entry]))
            ThemeService.setTheme(entry.id,true,false)
            return "ok"
        }
        function studioBurst(enabled:bool):string {
            if(!SettingsService.arrived)return "Settings are not ready"
            const sync=SettingsService.copy(SettingsService.moduleColourSync)||{}
            if(enabled && !sync.studioBurst){
                const previous={sync:SettingsService.copy(sync),colours:SettingsService.copy(SettingsService.shellColours)}
                const colours=SettingsService.copy(SettingsService.shellColours)||{}
                const palette=ThemeService.paletteFor(ThemeService.activeId)?.colors||ThemeService.dynamicColors||{}
                const accents=[palette.accent,palette.accentHover,palette.success,palette.warning,palette.error].filter(v=>/^#[0-9a-fA-F]{6}$/.test(v||""))
                if(!accents.length)accents.push(String(Theme.accent))
                const modules=["clock","media","battery","volume","brightness","network","bluetooth","notifications","weather","notes","launcher","controls","appearance"]
                for(let i=0;i<modules.length;i++){
                    const ink=Theme.colourChannels(accents[i%accents.length])
                    colours[modules[i]]=Object.assign({},colours[modules[i]]||{},{accent:accents[i%accents.length],background:String(Qt.rgba(ink.r*.10,ink.g*.10,ink.b*.10,1))})
                }
                SettingsService.set("shellColours",colours)
                SettingsService.set("moduleColourSync",Object.assign({},sync,{enabled:true,respectIndividual:true,studioBurst:true,studioBeforeBurst:previous}))
            }else if(!enabled && sync.studioBurst){
                const previous=sync.studioBeforeBurst
                if(previous){SettingsService.set("shellColours",previous.colours||{});SettingsService.set("moduleColourSync",previous.sync||{})}
            }
            return "ok"
        }
        function lockAnimationPreset(id:string):string {const p=LockAnimationPresetService.designs.concat(LockAnimationPresetService.saved).find(p=>p.id===id);if(!p)return "unknown preset";LockAnimationPresetService.apply(p.values);return "ok"}
        function lockPreset(id:string):string {const p=Config.LockDesignPresetService.designs.concat(Config.LockDesignPresetService.saved).find(p=>p.id===id);if(!p)return "unknown preset";Config.LockDesignPresetService.apply(p.values);return "ok"}
        function controlPreset(id:string):string {const p=ModulePresetService.list("controls").find(p=>p.id===id);if(!p)return "unknown preset";ModulePresetService.apply("controls",p.values);return "ok"}
        function restoreReferenceMotion():void {if(SettingsService.lockDesign==="reference"){const before=Config.LockDesignPresetService.saved.find(p=>p.name==="Before reference preset");if(before?.values.lockIslandEnabled!==undefined)SettingsService.set("lockIslandEnabled",before.values.lockIslandEnabled)}}
        function launcherPreset(id:string):string {const p=LauncherPresetService.designs.find(p=>p.id===id);if(!p)return "unknown preset";LauncherPresetService.apply(p.values);return "ok"}
        function referencePresetsStatus():string {return JSON.stringify({lock:Config.LockDesignPresetService.capture(),lockSaved:Config.LockDesignPresetService.saved.map(p=>({id:p.id,name:p.name})),controls:ModulePresetService.capture("controls"),bootSynced:LockStyleService.synced,bootError:LockStyleService.error})}
        function blur(app:string,enabled:bool):string {
            if(!["nautilus","settings"].includes(app))return "unknown app"
            SettingsService.set(app+"Blur",enabled)
            return "ok"
        }
        function nautilusMode(mode:string):string {
            if(!["tiled","floating"].includes(mode))return "unknown mode"
            SettingsService.set("nautilusWindowMode",mode)
            CompositorService.applyNautilusWindowMode()
            return "ok"
        }
        function shellMotion(id:string):string {const preset=Theme.motionPresets.find(p=>p.id===id);if(!preset)return "unknown preset";SettingsService.applyShellMotionPreset(preset);return "ok"}
        function hoverPreset(id:string):string {const p=ModulePresetService.list("summary").find(p=>p.id===id);if(!p)return "unknown preset";if(!ModulePresetService.list("summary").some(p=>p.name==="Before compact hover"))ModulePresetService.save("summary","Before compact hover");ModulePresetService.apply("summary",p.values);return "ok"}
        function clockSize(size:real):void {SettingsService.setSharedClockSize(size)}
        function hoverLayout(key:string,value:real):void {if(Object.prototype.hasOwnProperty.call(SettingsService.pristine.islandHoverLayout,key)&&key!=="enabled")SettingsService.setHoverLayout(key,value)}
        function hoverDesign(id:string):string {if(!["classic","status","compact","reference-compact"].includes(id))return "unknown design";SettingsService.set("islandHoverDesign",id);return "ok"}
        function moduleAnimation(id:string,document:string):string {const value=JSON.parse(document);for(const [key,taken] of Object.entries(value))if(Object.prototype.hasOwnProperty.call(SettingsService.pristine.moduleAnimations.all,key))SettingsService.setModuleMotion(id,key,taken);return "ok"}
        function syncModuleColours(enabled:bool):string {SettingsService.setSharedModuleColour("enabled",enabled);return "ok"}
        function moduleColours():string {return JSON.stringify({config:SettingsService.moduleColourSync,accent:String(Theme.accent),text:String(Theme.text),samples:["clock","media","battery","volume","notes","appearance","launcher","presets"].map(id=>({id:id,foreground:String(Theme.moduleColour(id,"foreground",Theme.text)),accent:String(Theme.moduleColour(id,"accent",Theme.accent)),muted:String(Theme.moduleColour(id,"muted",Theme.textMuted))}))})}
        function blurStatus():string {return JSON.stringify({nautilus:{enabled:SettingsService.nautilusBlur,profile:SettingsService.nautilusFrost},settings:{enabled:SettingsService.settingsBlur,profile:SettingsService.settingsFrost,background:String(SettingsDesignService.style.background)}})}
        function close():void {root.close()}
        function open(section: string, tab: string): string {
            root.open()
            root.requestedSection=section;root.requestedTab=tab;navigationTimer.restart()
            return "ok"
        }
        function design(id: string): string {
            const preset=SettingsDesignService.designs.find(p=>p.id===id)
            if(!preset)return "unknown design"
            SettingsDesignService.apply(preset.values)
            root.implicitWidth=Qt.binding(()=>SettingsDesignService.style.windowWidth)
            root.implicitHeight=Qt.binding(()=>SettingsDesignService.style.windowHeight)
            return "ok"
        }
        function overview(category:string):void {
            root.open()
            Qt.callLater(()=>{if(settingsLoader.item){settingsLoader.item.openOverview(category)}})
        }
        function preview():bool {
            return settingsLoader.grabToImage(result=>result.saveToFile("/tmp/hyprland-settings-preview.png"))
        }
        function sliderInfo(label:string):string {
            const pending=[settingsLoader.item]
            for(let n=0;n<pending.length&&n<12000;n++){
                const item=pending[n];if(!item)continue
                if(item.label===label&&typeof item.to==="number"&&typeof item.from==="number")return JSON.stringify({found:true,from:item.from,to:item.to,value:item.value})
                for(const child of item.children||[])pending.push(child)
            }
            return JSON.stringify({found:false})
        }
        function status(): string {
            const panel = settingsLoader.item
            return JSON.stringify({open:root.visible, design:SettingsDesignService.style.navigation,
                motion:panel?.navigationMotionState()||{},section:panel?.section || "", tab:panel?.tab || "", category:panel?.current.category || "", columns:panel?.presetColumns || 0, presets:panel?.displayedPresets || 0, previews:panel?.previewStats() || {}, barApplyMs:IslandPresetService.lastApplyMs, overview:panel?.atlasOverview || false})
        }
    }
    Component {
        id: panel

        SettingsPanel {
            onClosed: root.close()
            onMoveRequested:root.startSystemMove()
            onMinimizeRequested:root.minimized=true
            onMaximizeRequested:root.maximized=!root.maximized
            onPanelRequested: name => root.panelRequested(name)
        }
    }
}
