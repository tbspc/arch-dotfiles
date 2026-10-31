// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   T H E M E   S E R V I C E                                              │
// │   active palette · persistence and adaptive colours                      │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../theme"

// Owns which palette is active and keeps that choice across restarts.
QtObject {
    id: root

    readonly property string script: Quickshell.shellPath("scripts/theme_manager.py")

    signal themeRequested(string themeId)
    property bool paletteTransitionBusy:false
    readonly property Timer paletteWorkDelay:Timer {interval:Theme.paletteTransition+Theme.durationFast+50;onTriggered:{root.paletteTransitionBusy=false;root.flushTerminalPalette()}}

    property string activeId: "adaptive"
    property var dynamicColors: null

    // The adaptive entry has no static colours: they come from the wallpaper.
    readonly property var adaptiveTheme: ({
        id: "adaptive",
        name: "Adaptive (Wallpaper)",
        badge: "From Wallpaper",
        adaptive: true,
        colors: null
    })

    // Built from Palettes so a palette is described exactly once.
    readonly property var availableThemes: [root.adaptiveTheme].concat(Palettes.list).concat((SettingsService.savedColourThemes||[]).map(t=>({id:t.id,name:t.name,badge:"Saved colours",wallpaper:t.wallpaper,colors:t.colors,swatches:[t.colors.background,t.colors.surface,t.colors.accent,t.colors.text]})))

    // Theme membership is explicit: sourced collection folders, linked theme
    // wallpapers, or the user's additions. No image analysis on the UI thread.
    readonly property bool wallpaperFilterActive:SettingsService.wallpaperFilterByTheme&&root.activeId!=="adaptive"
    readonly property var browsableWallpapers:root.wallpaperFilterActive?root.wallpapersForTheme(root.activeId):WallpaperService.wallpapers
    readonly property var browsableAnimated:root.wallpaperFilterActive?WallpaperService.animated.filter(entry=>root.wallpaperBelongs(entry,root.activeId)):WallpaperService.animated
    function previewSwatches(entry:var):var {
        const c=entry?.adaptive?root.dynamicColors:entry?.colors
        if(!c)return []
        return [c.background,c.surfaceHover,c.accent,c.accentHover,c.textMuted,c.text].filter(value=>typeof value==="string")
    }
    function paletteFor(id:string):var {return root.availableThemes.find(theme=>theme.id===id)||null}
    function wallpaperBelongs(entry:var,id:string):bool {
        if(!entry)return false
        const linked=root.paletteFor(id)?.wallpaper
        return id==="adaptive"||(entry.themes||[]).includes(id)||entry.path===linked||(SettingsService.wallpaperThemeLinks[id]||[]).includes(entry.path)
    }
    function wallpapersForTheme(id:string):var {return WallpaperService.wallpapers.filter(entry=>root.wallpaperBelongs(entry,id)).sort((a,b)=>(a.themeMatchScores?.[id]??999)-(b.themeMatchScores?.[id]??999))}
    function setWallpaperMembership(id:string,path:string,included:bool):void {
        if(!id||id==="adaptive"||!path.startsWith("/"))return
        const links=SettingsService.copy(SettingsService.wallpaperThemeLinks)||{}
        const paths=(links[id]||[]).filter(value=>value!==path)
        if(included)paths.push(path)
        if(paths.length)links[id]=paths;else delete links[id]
        SettingsService.set("wallpaperThemeLinks",links)
    }

    property var requestedWallpaperThemes:({})
    function rememberThemeWallpaper(id:string,path:string):void {
        if(!SettingsService.arrived||!id||!path.startsWith("/"))return
        SettingsService.set("themeLastWallpapers",Object.assign({},SettingsService.themeLastWallpapers,{[id]:path}))
    }
    function restoreThemeWallpaper(id:string):void {
        const palette=root.paletteFor(id)
        const collection=root.wallpapersForTheme(id)
        const remembered=SettingsService.themeLastWallpapers[id]
        const previous=id==="adaptive"||collection.some(entry=>entry.path===remembered)||palette?.wallpaper===remembered?remembered:""
        const fallback=palette?.wallpaper||collection[0]?.path||""
        if(previous||fallback)ProfileService.showWallpaper(previous||fallback)
    }

    // The wallpaper colours once extracted, the current theme until then.
    readonly property var adaptiveSwatches: root.dynamicColors
        ? [root.dynamicColors.background, root.dynamicColors.surface,
           root.dynamicColors.accent, root.dynamicColors.text]
        : [Theme.background, Theme.surface, Theme.accent, Theme.text]

    // Reads the generated palette as soon as the wallpaper backend writes it.
    // That happens before its slower SDDM wallpaper copy finishes.
    readonly property FileView adaptiveColorsView: FileView {
        path: SettingsService.stateDirectory + "/dynamic-colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.acceptAdaptiveColors(text())
    }

    // Restores the persisted choice on startup.
    readonly property Process stateProcess: Process {
        command: [root.script, "get-state"]
        running: true
        stdout: StdioCollector {
            // streamFinished, not textChanged: the collector fires per chunk
            // and JSON.parse on half a document throws.
            onStreamFinished: {
                const state = root.parseJson(text, "shell state")
                if (state && state.activeTheme)
                    root.setTheme(state.activeTheme, false)
            }
        }
    }

    readonly property Process extractProcess: Process {
        command: [root.script, "extract-colors"]
        stdout: StdioCollector {
            onStreamFinished: root.acceptAdaptiveColors(text)
        }
    }

    property string pendingThemeId:""
    readonly property Process persistProcess: Process {onExited:root.flushThemeChoice()}
    function flushThemeChoice():void {
        if(root.persistProcess.running||root.pendingThemeId==="")return
        const themeId=root.pendingThemeId;root.pendingThemeId=""
        root.persistProcess.command=[root.script,"set-theme",themeId]
        root.persistProcess.running=true
    }
    readonly property string nautilusIcons:SettingsService.nautilusIconStyle
    onNautilusIconsChanged:if(SettingsService.arrived)iconDelay.restart()
    readonly property Timer iconDelay:Timer {interval:100;onTriggered:{if(iconProcess.running)restart();else{iconProcess.command=[root.script,"push-nautilus-icons",SettingsService.nautilusIconStyle,JSON.stringify(Theme.tokens)];iconProcess.running=true}}}
    readonly property Process iconProcess:Process {}


    property string pendingTerminalPalette:""
    property string lastTerminalPalette:""
    readonly property Process terminalProcess:Process{onExited:root.flushTerminalPalette()}
    property string pendingLivePalette:""
    property string lastLivePalette:""
    property bool spotifyPending:false
    readonly property Process livePaletteProcess:Process {
        onExited:{root.spotifyPending=true;root.flushLivePalette();root.flushSpotifyPalette();root.flushTerminalPalette()}
    }
    readonly property Process spotifyPaletteProcess:Process {onExited:root.flushSpotifyPalette()}
    function flushSpotifyPalette():void {
        if(!root.spotifyPending||root.livePaletteProcess.running||root.spotifyPaletteProcess.running)return
        root.spotifyPending=false
        root.spotifyPaletteProcess.command=["node",Quickshell.shellPath("scripts/spotify-live.cjs")]
        root.spotifyPaletteProcess.running=true
    }
    function flushLivePalette():void {
        if(root.livePaletteProcess.running||root.pendingLivePalette==="")return
        const document=root.pendingLivePalette;root.pendingLivePalette=""
        if(document===root.lastLivePalette){root.flushTerminalPalette();return}
        root.lastLivePalette=document
        root.livePaletteProcess.command=[root.script,"push-live-palette",document,"--nautilus-glass",String(root.filesGlass),"--dialog-glass",String(root.dialogsGlass)]
        root.livePaletteProcess.running=true
    }
    readonly property bool filesGlass:!SettingsService.gameMode&&(SettingsService.nautilusBlur||SettingsService.macGlassNautilus||SettingsService.macGlassWindows)
    readonly property string nautilusBlurCssKey:JSON.stringify({enabled:root.filesGlass,blur:SettingsService.nautilusBlur,opacity:SettingsService.nautilusFrost.opacity})
    property bool filesBlurAgain:false
    onNautilusBlurCssKeyChanged:if(SettingsService.arrived&&!filesBlurDelay.running)filesBlurDelay.start()
    function pushFilesBlur():void {
        if(filesBlurProcess.running){root.filesBlurAgain=true;return}
        root.filesBlurAgain=false
        filesBlurProcess.command=[root.script,"push-nautilus-blur",JSON.stringify({enabled:root.filesGlass,frost:SettingsService.nautilusBlur?SettingsService.nautilusFrost:null,colors:Theme.tokens})]
        filesBlurProcess.running=true
    }
    readonly property Timer filesBlurDelay:Timer {interval:50;onTriggered:root.pushFilesBlur()}
    readonly property Process filesBlurProcess:Process {onExited:if(root.filesBlurAgain)root.pushFilesBlur()}
    onFilesGlassChanged:if(SettingsService.arrived&&root.lastTerminalPalette!=="") {
        root.lastLivePalette="";root.pendingLivePalette=root.lastTerminalPalette;root.flushLivePalette()
    }

    readonly property bool dialogsGlass:!SettingsService.gameMode&&(SettingsService.macGlassFileDialogs||SettingsService.macGlassWindows)
    onDialogsGlassChanged:if(SettingsService.arrived&&root.lastTerminalPalette!==""){root.lastLivePalette="";root.pendingLivePalette=root.lastTerminalPalette;root.flushLivePalette()}
    readonly property Connections wallpaperIdle:Connections {target:WallpaperService;function onPickerClosingChanged(){if(!WallpaperService.pickerClosing)root.flushTerminalPalette()}}

    // ── FONT ────────────────────────────────────────────────────────────────
    //
    // The monospace family is pushed to kitty so the terminal follows the
    // setting.
    readonly property string terminalFont: SettingsService.fontMono

    onTerminalFontChanged: root.pushTerminalFont()

    function pushTerminalFont(): void {
        if (!SettingsService.arrived)
            return
        root.fontProcess.command = [root.script, "push-terminal-font",
                                    SettingsService.fontMono]
        if (root.fontProcess.running)
            root.fontAgain = true
        else
            root.fontProcess.running = true
    }

    // A push asked for while one runs goes again when it exits; a running
    // Process ignores being started.
    property bool fontAgain: false
    readonly property Process fontProcess: Process {
        onExited: if (root.fontAgain) {
            root.fontAgain = false
            root.pushTerminalFont()
        }
    }

    // ── GROUND ──────────────────────────────────────────────────────────────
    //
    // The terminal's ground, chosen beside the shell's.
    readonly property string terminalGround: SettingsService.terminalGround

    onTerminalGroundChanged: root.pushTerminalGround()
    readonly property string terminalFrostKey: JSON.stringify(SettingsService.terminalFrost)
    onTerminalFrostKeyChanged: if (SettingsService.terminalGround === "blur" && !frostGroundUpdate.running) frostGroundUpdate.start()
    readonly property Timer frostGroundUpdate: Timer {interval:50;onTriggered:root.pushTerminalGround()}

    function pushTerminalGround(): void {
        if (!SettingsService.arrived)
            return
        root.groundProcess.command = [root.script, "push-terminal-ground",
                                      SettingsService.terminalGround, JSON.stringify(SettingsService.terminalFrost)]
        if (root.groundProcess.running)
            root.groundAgain = true
        else
            root.groundProcess.running = true
    }

    property bool groundAgain: false
    readonly property Process groundProcess: Process {
        onExited: if (root.groundAgain) {
            root.groundAgain = false
            root.pushTerminalGround()
        }
    }

    // Also pushed at startup, once the settings are read: before that they
    // hold the defaults, and a setting that never changes would leave the
    // fragment kitty.conf includes unwritten.
    function pushTerminalSettings(): void {
        root.pushTerminalFont()
        root.pushTerminalGround()
        root.pushGreeting()
    }

    Component.onCompleted: root.pushTerminalSettings()

    readonly property Connections settingsArrival: Connections {
        target: SettingsService
        function onArrivedChanged(): void {
            root.pushTerminalSettings()
        }
    }

    // ── GREETING ────────────────────────────────────────────────────────────
    //
    // Which scene `fa` shows. The palette push redraws all of them
    // (`greeting.py`); this only records the choice. `random` is resolved
    // by `fa`.
    readonly property var greetings: [
        { id: "lava", label: "Lava lamp" },
        { id: "critters", label: "Critters" },
        { id: "koi", label: "Koi" },
        { id: "invaders", label: "Invaders" },
        { id: "random", label: "Random" }
    ]

    readonly property string greetingScript: Quickshell.shellPath("scripts/greeting.py")
    readonly property string greeting: SettingsService.greeting

    onGreetingChanged: root.pushGreeting()

    // A running Process ignores being started again, so queue the latest
    // pick.
    property bool greetingPending: false

    function pushGreeting(): void {
        if (root.greetingProcess.running) {
            root.greetingPending = true
            return
        }
        root.greetingProcess.command = [root.greetingScript, "choose", SettingsService.greeting]
        root.greetingProcess.running = true
    }

    readonly property Process greetingProcess: Process {
        onExited: {
            if (root.greetingPending) {
                root.greetingPending = false
                root.pushGreeting()
            }
        }
    }

    // Written by `greeting.py` once every scene is redrawn. The settings
    // tiles reload on this rather than on the palette change, when the new
    // scenes are still being drawn.
    property string greetingStamp: ""

    readonly property FileView greetingStampView: FileView {
        path: `${SettingsService.stateDirectory}/greeting.stamp`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.greetingStamp = text().trim()
    }

    // The backend writes the colour fragment kitty.conf includes and repaints
    // open kitty windows.
    function pushTerminal(colors:var):void {
        if(!colors)return
        root.pendingTerminalPalette=JSON.stringify(colors)
        root.pendingLivePalette=root.pendingTerminalPalette
        root.flushLivePalette()
        root.flushTerminalPalette()
    }
    function flushTerminalPalette():void {
        if(root.paletteTransitionBusy||WallpaperService.pickerClosing||root.terminalProcess.running||root.livePaletteProcess.running||root.pendingLivePalette!==""||root.pendingTerminalPalette==="")return
        const document=root.pendingTerminalPalette
        root.pendingTerminalPalette=""
        if(document===root.lastTerminalPalette)return
        root.lastTerminalPalette=document
        root.terminalProcess.command=[root.script,"push-terminal-palette",document,"--defer-live"]
        root.terminalProcess.running=true
    }

    function parseJson(text: string, what: string): var {
        if (!text || text.trim() === "")
            return null
        try {
            return JSON.parse(text)
        } catch (error) {
            console.warn(`Cannot parse ${what}:`, error)
            return null
        }
    }

    property bool waitingForWallpaper:false
    readonly property Timer wallpaperColorDelay:Timer {
        interval:0
        onTriggered:{
            root.waitingForWallpaper=false
            if(root.activeId==="adaptive"&&root.dynamicColors)Theme.apply(root.dynamicColors,root.adaptiveTheme.name)
        }
    }
    readonly property Connections wallpaperTiming:Connections {
        target:WallpaperService
        function onWallpaperRequested(path:string):void {
            root.requestedWallpaperThemes=Object.assign({},root.requestedWallpaperThemes,{[path]:root.activeId})
            root.wallpaperColorDelay.stop()
            root.waitingForWallpaper=true
        }
        function onAdaptiveWallpaperRequested(path:string):void {
            root.requestedWallpaperThemes=Object.assign({},root.requestedWallpaperThemes,{[path]:"adaptive"})
            root.setTheme("adaptive",true,false)
        }
        function onWallpaperVisible(path:string):void {
            root.wallpaperColorDelay.stop()
            root.waitingForWallpaper=false
            if(root.activeId==="adaptive"&&root.dynamicColors)Theme.apply(root.dynamicColors,root.adaptiveTheme.name)
        }
        function onApplied(path:string):void {
            const chosen=WallpaperService.currentMotion||path
            const owner=root.requestedWallpaperThemes[chosen]
            if(owner){root.rememberThemeWallpaper(owner,chosen);const pending=Object.assign({},root.requestedWallpaperThemes);delete pending[chosen];root.requestedWallpaperThemes=pending}
            if(root.waitingForWallpaper) {
                root.waitingForWallpaper=false
                if(root.activeId==="adaptive"&&root.dynamicColors)Theme.apply(root.dynamicColors,root.adaptiveTheme.name)
            }
        }
    }
    readonly property Connections colorTimingSetting:Connections {
        target:SettingsService
        function onWallpaperColorsAfterTransitionChanged():void {
            if(!SettingsService.wallpaperColorsAfterTransition){
                root.wallpaperColorDelay.stop();root.waitingForWallpaper=false
                if(root.activeId==="adaptive"&&root.dynamicColors)Theme.apply(root.dynamicColors,root.adaptiveTheme.name)
            }
        }
    }

    function acceptAdaptiveColors(document: string): void {
        const colors = root.parseJson(document, "wallpaper colours")
        if (!colors)
            return
        if(JSON.stringify(root.dynamicColors)===JSON.stringify(colors))return
        root.dynamicColors = colors
        if (root.activeId === "adaptive") {
            if(!SettingsService.wallpaperColorsAfterTransition||!root.waitingForWallpaper)
                Theme.apply(colors, root.adaptiveTheme.name)
            root.pushTerminal(colors)
        }
    }

    function reloadAdaptiveColors(): void {
        root.extractProcess.running = true
    }

    property string colourThemeMessage:""
    function saveColourTheme(name:string, customColors = null, wallpaper = ""):string {
        if(!SettingsService.arrived)return ""
        const colors={};for(const key of Theme.tokens)colors[key]=String(Theme[key==="textMuted"?"paletteMuted":key])
        if(customColors)for(const key of Theme.tokens)if(/^#[0-9a-fA-F]{6}$/.test(customColors[key]||""))colors[key]=customColors[key]
        const settings={}
        for(const key of ["moduleColourSync","shellColours","sidebarColours","surfaceStyle","desktopGround","dockGround","terminalGround","floatingBarSurface","liquidOpacity","liquidOldOpacity","liquidTint","liquidShine","liquidRefraction","liquidBlur","macGlassRefraction","macGlassBlur","macGlassTint","macGlassShine","macGlassRefractionMode","macGlassEdgeWidth","macGlassSpread","macGlassCentreStrength","macGlassFlow","macGlassWindows","macGlassSettings","macGlassTerminal"])
            settings[key]=SettingsService.copy(SettingsService[key])
        for(const [key,value] of Object.entries(SettingsService.snapshot())) {
            if(!key.startsWith("wallpaper") && !["savedColourThemes","macGlassLive"].includes(key) && /colou?r|tint|accent|opacity|ground|surface|shine|glass|lockFieldMaterial/i.test(key))settings[key]=SettingsService.copy(value)
        }
        const design={};for(const key of ["appearanceVariant","colourMode","surfaceTone","accentColor","useThemeAccent","colourOverrides","opaque","background","sidebarBackground","cardBackground","fieldBackground","textColor","mutedColor","borderColor","hoverColor"])if(SettingsService.settingsDesign[key]!==undefined)design[key]=SettingsService.copy(SettingsService.settingsDesign[key])
        // Freeze accent-based overrides into the saved colour snapshot.
        for(const [id,roles] of Object.entries(settings.shellColours||{}))for(const role of Object.keys(roles)) {
            if(roles[role]==="wallpaper")roles[role]=String(root.dynamicColors?.accent || Theme.accent)
            else if(roles[role]==="accent")roles[role]=String(colors.accent)
        }
        for(const id of Object.keys(settings.sidebarTextColours||{})) {
            if(settings.sidebarTextColours[id]==="wallpaper")settings.sidebarTextColours[id]=String(root.dynamicColors?.accent || Theme.accent)
            else if(settings.sidebarTextColours[id]==="accent")settings.sidebarTextColours[id]=String(colors.accent)
        }
        for(const id of Object.keys(settings.sidebarColours||{})) {
            if(settings.sidebarColours[id]==="wallpaper")settings.sidebarColours[id]=String(root.dynamicColors?.accent || Theme.accent)
            else if(settings.sidebarColours[id]==="accent")settings.sidebarColours[id]=String(colors.accent)
        }
        settings.settingsDesignColours=design
        const elementColours={}
        for(const [id,elements] of Object.entries(SettingsService.moduleElements||{}))for(const [key,value] of Object.entries(elements))if(value.color!==undefined){if(!elementColours[id])elementColours[id]={};elementColours[id][key]=value.color}
        settings.elementColours=elementColours
        const theme={id:"saved-colours-"+Date.now(),name:(name||"My colour theme").trim().slice(0,48),colors,settings}
        if(wallpaper.startsWith("/"))theme.wallpaper=wallpaper
        SettingsService.set("savedColourThemes",(SettingsService.savedColourThemes||[]).concat([theme]))
        root.colourThemeMessage="Saved "+theme.name
        return theme.id
    }
    function deleteColourTheme(id:string):void {SettingsService.set("savedColourThemes",SettingsService.savedColourThemes.filter(t=>t.id!==id));if(root.activeId===id)root.setTheme("adaptive")}
    function restoreThemeSettings(theme):void {
        for(const [key,value] of Object.entries(theme.settings||{})) {
            // A colour theme must not enable glass or replace surface modes.
            if(/^(surfaceStyle|desktopGround|dockGround|terminalGround|floatingBarSurface|macGlass|liquid|terminalFrost|nautilusFrost|settingsFrost|nautilusBlur|settingsBlur|lockFieldMaterial)/.test(key))continue
            if(["moduleColourSync","shellColours","elementColours"].includes(key))continue
            if(key==="settingsDesignColours") {
                const colours=SettingsService.copy(value)
                delete colours.opaque
                SettingsService.set("settingsDesign",Object.assign({},SettingsService.settingsDesign,colours))
            }
            else SettingsService.set(key,SettingsService.copy(value))
        }
    }
    function applyThemeModuleColours(theme:var,enabled:bool):void {
        if(!SettingsService.arrived)return
        const saved=theme?.settings||{}
        const sync=saved.moduleColourSync
        const next=sync && typeof sync==="object" && !Array.isArray(sync)
            ? Object.assign({},SettingsService.copy(SettingsService.pristine.moduleColourSync),SettingsService.copy(sync),{enabled})
            : Object.assign({},SettingsService.copy(SettingsService.pristine.moduleColourSync),{enabled})
        SettingsService.set("moduleColourSync",next)
        SettingsService.set("shellColours",SettingsService.copy(saved.shellColours)||{})
        const elements=SettingsService.copy(SettingsService.moduleElements)||{}
        // Themes own colours; the editor retains its layout and dimensions.
        for(const values of Object.values(elements))for(const element of Object.values(values))delete element.color
        for(const [id,values] of Object.entries(saved.elementColours||{})) {
            if(!elements[id])elements[id]={}
            for(const [key,color] of Object.entries(values))elements[id][key]=Object.assign({},elements[id][key],{color})
        }
        if(JSON.stringify(elements)!==JSON.stringify(SettingsService.moduleElements))SettingsService.set("moduleElements",elements)
    }
    readonly property Connections savedThemeReady:Connections {target:SettingsService;function onArrivedChanged(){if(SettingsService.arrived&&root.activeId.startsWith("saved-colours-"))root.setTheme(root.activeId,false)}}
    function setTheme(themeId: string, persist = true, restoreWallpaper = true): void {
        const sharedEnabled=SettingsService.moduleColourSync.enabled===true
        if(persist&&root.activeId!==themeId&&WallpaperService.wallpaperStateLoaded&&!WallpaperService.applyingWallpaper&&!WallpaperService.pendingWallpaper&&!root.waitingForWallpaper&&WallpaperService.chosen)
            root.rememberThemeWallpaper(root.activeId,WallpaperService.chosen)
        if(persist)root.themeRequested(themeId)
        root.activeId = themeId
        Theme.activeId = themeId
        root.paletteTransitionBusy=Theme.paletteTransition>0
        if(root.paletteTransitionBusy)root.paletteWorkDelay.restart();else root.paletteWorkDelay.stop()

        if (themeId === "adaptive") {
            if(persist)root.applyThemeModuleColours(null,sharedEnabled)
            if (root.dynamicColors) {
                if(!SettingsService.wallpaperColorsAfterTransition||!root.waitingForWallpaper)
                    Theme.apply(root.dynamicColors, root.adaptiveTheme.name)
                root.pushTerminal(root.dynamicColors)
            } else {
                root.reloadAdaptiveColors()
            }
        } else {
            const palette = SettingsService.savedColourThemes.find(t=>t.id===themeId)||Palettes.byId(themeId)
            if (palette) {
                if(palette.settings)root.restoreThemeSettings(palette)
                if(persist)root.applyThemeModuleColours(palette,sharedEnabled)
                Theme.apply(palette.colors, palette.name)
                root.pushTerminal(palette.colors)
                // Last-used wallpaper restoration is shared with Adaptive below.
            } else {
                console.warn("Unknown palette:", themeId)
            }
        }

        if(persist&&restoreWallpaper)root.restoreThemeWallpaper(themeId)
        if (persist) {
            root.pendingThemeId=themeId
            root.flushThemeChoice()
        }
    }
}
