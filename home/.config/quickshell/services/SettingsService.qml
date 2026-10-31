// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E T T I N G S   S E R V I C E                                        │
// │   user preferences · defaults here, overrides on disk                    │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Every user preference. Defaults are the initialisers in `Store`; changes go
// to $XDG_STATE_HOME/quickshell/settings.json, outside the files `./setup`
// manages. JsonAdapter writes the file back on every change.
Singleton {
    id: root

    readonly property string stateDirectory:
        `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/quickshell`

    // ── ACCESS ──────────────────────────────────────────────────────────────

    readonly property alias clockFormat: config.clockFormat
    readonly property alias clockShowsDate: config.clockShowsDate
    readonly property alias clockShowsSeconds: config.clockShowsSeconds
    readonly property alias moduleRounding: config.moduleRounding
    readonly property alias moduleAppearance: config.moduleAppearance
    readonly property alias moduleColourSync:config.moduleColourSync
    readonly property alias shellColours:config.shellColours
    readonly property alias sidebarColours:config.sidebarColours
    readonly property alias sidebarTextColours:config.sidebarTextColours
    readonly property alias savedColourThemes:config.savedColourThemes
    readonly property alias nautilusWindowMode:config.nautilusWindowMode
    readonly property alias nautilusIconStyle:config.nautilusIconStyle
    readonly property alias notchShoulderRoundingPower:config.notchShoulderRoundingPower
    readonly property alias notchRoundingPower:config.notchRoundingPower
    readonly property alias workspaceInactiveBrightness:config.workspaceInactiveBrightness
    readonly property alias workspaceOccupiedBrightness:config.workspaceOccupiedBrightness
    readonly property alias notchCornerRadius:config.notchCornerRadius
    readonly property alias notchShoulderRadius:config.notchShoulderRadius
    readonly property alias notchOffsetX:config.notchOffsetX
    readonly property alias powerSaverBarEffects:config.powerSaverBarEffects
    readonly property alias chipFollowModules:config.chipFollowModules
    readonly property alias chipHideDuration:config.chipHideDuration
    readonly property alias chipShowDuration:config.chipShowDuration
    readonly property alias chipReturnDelay:config.chipReturnDelay
    readonly property alias macGlassRefractionRange:config.macGlassRefractionRange
    readonly property alias macGlassRefractionMode:config.macGlassRefractionMode
    readonly property alias macGlassEdgeWidth:config.macGlassEdgeWidth
    readonly property alias macGlassSpread:config.macGlassSpread
    readonly property alias macGlassCentreStrength:config.macGlassCentreStrength
    readonly property alias macGlassFlow:config.macGlassFlow

    readonly property alias moduleElements: config.moduleElements
    readonly property alias islandChipsEnabled: config.islandChipsEnabled
    readonly property alias islandChipSettings: config.islandChipSettings
    readonly property alias islandActivitiesSeen:config.islandActivitiesSeen
    readonly property alias islandChipGap: config.islandChipGap
    readonly property alias workspaceDimensions: config.workspaceDimensions
    readonly property alias cursorStyle: config.cursorStyle
    readonly property alias notesBodyFont: config.notesBodyFont
    readonly property alias maximizedBarGap: config.maximizedBarGap
    readonly property alias lockIslandEnabled: config.lockIslandEnabled
    readonly property alias barEntryEnabled:config.barEntryEnabled
    readonly property alias barEntryOnUnlock:config.barEntryOnUnlock
    readonly property alias barEntryAnimation:config.barEntryAnimation
    readonly property alias barEntryDuration:config.barEntryDuration
    readonly property alias barEntryHold:config.barEntryHold
    readonly property alias barEntryUnlockLead:config.barEntryUnlockLead
    readonly property alias lockIslandTransition:config.lockIslandTransition
    readonly property alias lockIslandTransitionDuration:config.lockIslandTransitionDuration
    readonly property alias lockIslandOpenHold:config.lockIslandOpenHold
    readonly property alias lockIslandCloseDuration:config.lockIslandCloseDuration
    readonly property alias lockAnimation: config.lockAnimation
    readonly property alias lockUnlockMovement:config.lockUnlockMovement
    readonly property alias lockUnlockDuration:config.lockUnlockDuration
    readonly property alias lockAnimationDuration: config.lockAnimationDuration
    readonly property alias lockAnimationSpeed: config.lockAnimationSpeed
    readonly property alias lockAnimationMovement: config.lockAnimationMovement
    readonly property alias lockAnimationBounciness: config.lockAnimationBounciness
    readonly property alias lockAnimationRebounds: config.lockAnimationRebounds
    readonly property int lockDuration: lockAnimation === "none" ? 0
        : Math.round(lockAnimationDuration * 100 / Math.max(50, Math.min(200, lockAnimationSpeed)))
    readonly property alias lockSlideDistance: config.lockSlideDistance
    readonly property alias islandBattery: config.islandBattery
    readonly property alias islandBatteryGlow:config.islandBatteryGlow
    readonly property alias islandBatteryFillOpacity:config.islandBatteryFillOpacity
    readonly property alias islandBatteryEmptyOpacity:config.islandBatteryEmptyOpacity
    readonly property alias islandBatteryTipOpacity:config.islandBatteryTipOpacity
    readonly property alias islandBatteryIconStyle: config.islandBatteryIconStyle
    readonly property alias islandBatteryMode: config.islandBatteryMode
    readonly property alias islandWorkspaces: config.islandWorkspaces
    readonly property alias islandWorkspacesGlow: config.islandWorkspacesGlow
    readonly property alias workspaceGlowRange:config.workspaceGlowRange
    readonly property alias workspaceGlowIntensity:config.workspaceGlowIntensity
    readonly property alias workspaceGlowSpread:config.workspaceGlowSpread
    readonly property alias islandWorkspacesPosition: config.islandWorkspacesPosition
    readonly property alias islandInternet: config.islandInternet
    readonly property alias islandInternetPosition: config.islandInternetPosition
    readonly property alias islandInternetStyle: config.islandInternetStyle
    readonly property alias islandBatteryPosition: config.islandBatteryPosition
    readonly property alias islandClockSize: config.islandClockSize
    readonly property alias islandLayout: config.islandLayout
    readonly property alias islandPillWidth: config.islandPillWidth
    readonly property alias islandPaddingLeft: config.islandPaddingLeft
    readonly property alias islandPaddingRight: config.islandPaddingRight
    readonly property alias islandWorkspacesOffset: config.islandWorkspacesOffset
    readonly property alias islandInternetOffset: config.islandInternetOffset
    readonly property alias islandBatteryOffset: config.islandBatteryOffset
    readonly property alias islandWorkspacesScale: config.islandWorkspacesScale
    readonly property alias islandInternetScale: config.islandInternetScale
    readonly property alias islandBatteryScale: config.islandBatteryScale
    readonly property alias islandBluetooth: config.islandBluetooth
    readonly property alias islandBluetoothPosition: config.islandBluetoothPosition
    readonly property alias islandBluetoothOffset: config.islandBluetoothOffset
    readonly property alias islandBluetoothScale: config.islandBluetoothScale
    readonly property alias islandSpeaker: config.islandSpeaker
    readonly property alias islandSpeakerPercent: config.islandSpeakerPercent
    readonly property alias islandSpeakerPosition: config.islandSpeakerPosition
    readonly property alias islandSpeakerOffset: config.islandSpeakerOffset
    readonly property alias islandSpeakerScale: config.islandSpeakerScale
    readonly property alias barScale:config.barScale
    readonly property alias settingsWindowMode:config.settingsWindowMode
    readonly property alias barHeight: config.barHeight
    readonly property alias barMargin: config.barMargin
    readonly property alias islandAttached: config.islandAttached
    readonly property alias islandFloatingGap: config.islandFloatingGap
    readonly property alias barSideMargin: config.barSideMargin
    readonly property alias floatingBarSurface:config.floatingBarSurface
    readonly property alias barStyle: config.barStyle
    readonly property alias barEverywhere: config.barEverywhere
    readonly property alias barHidden: config.barHidden
    readonly property alias screenCorners: config.screenCorners
    readonly property alias gameMode: config.gameMode
    readonly property alias barLeft: config.barLeft
    readonly property alias barRight: config.barRight
    readonly property alias islandHoverDateFollowBar:config.islandHoverDateFollowBar
    readonly property alias islandHoverDatePosition:config.islandHoverDatePosition
    readonly property alias islandHoverTopLeft:config.islandHoverTopLeft
    readonly property alias islandHoverTopRight:config.islandHoverTopRight
    readonly property alias barHoverExtraWidth:config.barHoverExtraWidth
    readonly property alias barHoverExtraHeight:config.barHoverExtraHeight
    readonly property alias barHoverEnlargeBackgroundOnly:config.barHoverEnlargeBackgroundOnly
    readonly property alias barHoverEnlargeAmount:config.barHoverEnlargeAmount
    readonly property alias barHoverHighlight:config.barHoverHighlight
    readonly property alias barClickHoverEnlarge:config.barClickHoverEnlarge
    readonly property alias islandHoverLayout:config.islandHoverLayout
    function setSharedClockSize(value:real):void {
        const size=Math.max(10,Math.min(64,Math.round(value)))
        root.set("islandClockSize",size)
        const elements=root.copy(root.moduleElements),clock=elements.bar?.["design:ClockModule:6"]
        if(clock&&typeof clock.fontSize==="number"){delete clock.fontSize;root.set("moduleElements",elements)}
        root.setHoverLayout("clockSize",size)
    }
    function setHoverLayout(key:string,value:var):void {const base=Object.assign({},root.pristine.islandHoverLayout,root.islandHoverLayout);if(!base.enabled){base.width=root.islandHoverDesign==="compact"?620:760;base.height=root.islandHoverDesign==="compact"?84:96}root.set("islandHoverLayout",Object.assign(base,{enabled:true,[key]:value}))}
    readonly property alias islandHoverDesign:config.islandHoverDesign
    readonly property alias islandHoverMediaAutoHide:config.islandHoverMediaAutoHide
    readonly property alias islandHoverOpenDelay:config.islandHoverOpenDelay
    readonly property alias islandHoverCloseDelay:config.islandHoverCloseDelay
    readonly property alias shellBounceStrength:config.shellBounceStrength
    readonly property alias shellBounceCycles:config.shellBounceCycles
    readonly property alias shellMovement:config.shellMovement
    readonly property alias shellFadeDuration:config.shellFadeDuration
    readonly property alias shellExpandDuration:config.shellExpandDuration
    readonly property alias shellCloseMode:config.shellCloseMode
    function applyShellMotionPreset(preset:var):void {
        root.set("gameMode",false)
        root.set("motionScale",preset.scale)
        root.set("motionCurve",preset.curve)
        const baseline={shellExpandDuration:380,shellFadeDuration:100,shellShapeSpring:45,shellMovement:100,shellCloseMode:"parallel"}
        for(const [key,value] of Object.entries(Object.assign(baseline,preset.settings||{})))root.set(key,value)
        if(!preset.settings?.shellBezier)root.setShellBezier("enabled",false)
        if(!preset.settings?.shellSpring)root.setShellSpring("enabled",false)
        if(preset.moduleOverrides)root.set("moduleAnimations",root.copy(preset.moduleOverrides))
    }
    readonly property alias shellShapeSpring:config.shellShapeSpring
    readonly property alias shellBounceDamping:config.shellBounceDamping
    readonly property alias shellFadeDistance:config.shellFadeDistance
    readonly property alias shellZoomAmount:config.shellZoomAmount
    readonly property alias shellBezier:config.shellBezier
    function setShellBezier(key:string,value:var):void {root.set("shellBezier",Object.assign({},root.shellBezier,{[key]:value}))}
    readonly property alias windowMotion:config.windowMotion
    function setWindowMotion(key:string,value:var):void {root.set("windowMotion",Object.assign({},root.windowMotion,{[key]:value}))}
    readonly property alias shellSpring:config.shellSpring
    readonly property alias savedShellMotionPresets:config.savedShellMotionPresets
    function setShellSpring(key:string,value:var):void {root.set("shellSpring",Object.assign({},root.pristine.shellSpring,root.shellSpring,{[key]:value}))}
    readonly property var shellMotionKeys:["motionScale","motionCurve","shellExpandDuration","shellCloseMode","shellShapeSpring","shellBounceStrength","shellBounceCycles","shellBounceDamping","shellMovement","shellFadeDuration","shellFadeDistance","shellZoomAmount","shellBezier","shellSpring","islandHoverOpenDelay","islandHoverCloseDelay"]
    function captureShellMotion():var {const settings={};for(const key of root.shellMotionKeys)settings[key]=root.copy(root[key]);return {scale:root.motionScale,curve:root.motionCurve,settings:settings,moduleOverrides:root.copy(root.moduleAnimations)}}
    function saveShellMotionPreset(name:string):void {const values=root.captureShellMotion();root.set("savedShellMotionPresets",root.savedShellMotionPresets.concat([Object.assign({id:"shell-motion-"+Date.now(),name:(name||"My animation").trim().slice(0,64)},values)]))}
    function updateShellMotionPreset(id:string):void {const values=root.captureShellMotion();root.set("savedShellMotionPresets",root.savedShellMotionPresets.map(p=>p.id===id?Object.assign({},p,values):p))}
    function removeShellMotionPreset(id:string):void {root.set("savedShellMotionPresets",root.savedShellMotionPresets.filter(p=>p.id!==id))}
    readonly property alias moduleAnimations:config.moduleAnimations
    readonly property var moduleAnimationPresets:[
        {id:"theme",label:"Shell style",duration:380,curve:"OutCubic"},
        {id:"smooth",label:"Smooth expand",duration:380,curve:"OutCubic"},
        {id:"soft",label:"Soft bloom",duration:480,curve:"OutQuint"},
        {id:"width-first",label:"Width first",duration:460,curve:"OutCubic"},
        {id:"height-first",label:"Height first",duration:460,curve:"OutCubic"},
        {id:"cinematic",label:"Cinematic",duration:560,curve:"InOutCubic"}
    ]
    function moduleMotion(id:string):var {
        const values=Object.assign({},root.pristine.moduleAnimations.all,root.moduleAnimations.all||{},id!=="all"?root.moduleAnimations.bar||{}:{},root.moduleAnimations[id]||{})
        // One source of motion at a time: inherit shell, or use this override.
        if(values.followShell!==false) {
            const bouncy=["OutBack","OutBounce","OutElastic","InOutBack"].includes(root.motionCurve)
            return Object.assign(values,{engine:root.shellSpring.enabled?"spring":"easing",spring:root.copy(root.shellSpring),followShell:true,closeParallel:root.shellCloseMode==="parallel",exactDuration:false,customCurve:false,preset:"theme",curve:"preset",speed:100,contentFade:100,matchClosing:true,closePreset:"theme",closeCurve:"preset",closeSpeed:100,closeFade:100,hoverCloseSpeed:100,hoverCloseBounce:bouncy?Math.min(120,45*root.shellBounceStrength/100):0})
        }
        return values
    }
    function setModuleMotion(id:string,key:string,value:var):void {
        const next=root.copy(root.moduleAnimations)
        next[id]=Object.assign({},next[id]||{},{[key]:value})
        if(["preset","curve","speed","contentFade","matchClosing","closePreset","closeCurve","closeSpeed","closeFade","hoverCloseSpeed","hoverCloseBounce","exactDuration","openDuration","closeDuration","customCurve","bezierX1","bezierY1","bezierX2","bezierY2","closeParallel"].includes(key))next[id].followShell=key==="preset"&&value==="theme"
        root.set("moduleAnimations",next)
    }
    readonly property alias islandSummary: config.islandSummary
    readonly property string islandSummaryMode:config.barAutoHide?"click":config.islandSummaryMode
    readonly property string preferredIslandSummaryMode:config.islandSummaryMode
    readonly property alias lyrics: config.lyrics
    readonly property alias islandActivities: config.islandActivities
    readonly property alias chipShape: config.chipShape
    readonly property alias chipFigure: config.chipFigure
    readonly property alias desktopWidgets: config.desktopWidgets
    readonly property alias desktopTheme: config.desktopTheme
    readonly property alias desktopOpacity: config.desktopOpacity
    readonly property alias desktopHidden: config.desktopHidden
    readonly property alias centreButtons: config.centreButtons
    readonly property alias centreTop: config.centreTop
    readonly property alias centreBlocks: config.centreBlocks
    readonly property alias centreColumns: config.centreColumns
    readonly property alias centreRows: config.centreRows
    readonly property alias centreToggles: config.centreToggles
    readonly property alias dockEnabled: config.dockEnabled
    readonly property alias dockPinned: config.dockPinned
    readonly property alias dockEdge: config.dockEdge
    readonly property alias dockAlignment: config.dockAlignment
    readonly property alias dockIconSize: config.dockIconSize
    readonly property alias dockMagnify: config.dockMagnify
    readonly property alias dockOpacity: config.dockOpacity
    readonly property alias dockGround: config.dockGround
    readonly property alias nautilusBlur: config.nautilusBlur
    readonly property alias nautilusFrost: config.nautilusFrost
    readonly property alias settingsBlur: config.settingsBlur
    readonly property alias settingsFrost: config.settingsFrost
    readonly property alias terminalFrost: config.terminalFrost
    readonly property alias terminalGround: config.terminalGround
    readonly property alias dockRunning: config.dockRunning
    readonly property alias dockEverywhere: config.dockEverywhere
    readonly property alias dockAutohide: config.dockAutohide
    readonly property alias dockLauncher: config.dockLauncher
    readonly property alias weatherPlace: config.weatherPlace
    readonly property alias githubUser: config.githubUser
    readonly property alias markets: config.markets
    readonly property alias petStyle: config.petStyle
    readonly property alias emojiFollowsLauncher:config.emojiFollowsLauncher
    readonly property alias settingsDesign:config.settingsDesign
    readonly property alias launcherStyle:config.launcherStyle
    readonly property alias launcherResults: config.launcherResults
    readonly property alias launcherOrder: config.launcherOrder
    readonly property alias launcherFits: config.launcherFits
    readonly property alias emojiTone: config.emojiTone
    readonly property alias cameraEnabled: config.cameraEnabled
    readonly property alias cameraEffect: config.cameraEffect
    readonly property alias cameraReactions: config.cameraReactions
    readonly property alias clipboardHistory: config.clipboardHistory
    readonly property alias clipboardKeep: config.clipboardKeep
    readonly property alias clipboardImages: config.clipboardImages
    readonly property alias clipboardWipeOnLock: config.clipboardWipeOnLock
    readonly property alias lockDesign: config.lockDesign
    readonly property alias centreDesign: config.centreDesign
    readonly property alias lockClockSize: config.lockClockSize
    readonly property alias lockDateSize: config.lockDateSize
    readonly property alias lockClockTop: config.lockClockTop
    readonly property alias lockClockOpacity: config.lockClockOpacity
    readonly property alias lockDateOpacity: config.lockDateOpacity
    readonly property alias lockClockShadow: config.lockClockShadow
    readonly property alias lockShowsDate: config.lockShowsDate
    readonly property alias lockTimeFormat: config.lockTimeFormat
    readonly property alias lockFont: config.lockFont
    readonly property alias lockInk: config.lockInk
    readonly property alias lockAvatarSize: config.lockAvatarSize
    readonly property alias lockAccountBottom: config.lockAccountBottom
    readonly property alias lockProfileGap: config.lockProfileGap
    readonly property alias lockPromptGap: config.lockPromptGap
    readonly property alias lockNameSize: config.lockNameSize
    readonly property alias lockFieldWidth: config.lockFieldWidth
    readonly property alias lockFieldHeight: config.lockFieldHeight
    readonly property alias lockFieldOpacity: config.lockFieldOpacity
    readonly property alias lockFieldBorderOpacity: config.lockFieldBorderOpacity
    readonly property alias lockDim: config.lockDim
    readonly property alias lockExtraBlur: config.lockExtraBlur
    readonly property alias lockStatus: config.lockStatus
    readonly property alias lockHint: config.lockHint
    readonly property alias lockIdleHint: config.lockIdleHint
    readonly property alias lockPlaceholder: config.lockPlaceholder
    readonly property alias lockBackdrop:config.lockBackdrop
    readonly property alias lockVibrance:config.lockVibrance
    readonly property alias lockBlur: config.lockBlur
    readonly property alias lockClock: config.lockClock
    readonly property alias lockMusic: config.lockMusic
    readonly property alias lockMusicGround: config.lockMusicGround
    readonly property alias userName: config.userName
    readonly property alias userAvatar: config.userAvatar
    readonly property alias doNotDisturb: config.doNotDisturb
    readonly property alias recorderAudio: config.recorderAudio
    readonly property alias captureShape: config.captureShape
    readonly property alias captureKind: config.captureKind
    readonly property alias notesHandwriting: config.notesHandwriting
    readonly property alias deckOnEmpty: config.deckOnEmpty
    readonly property alias spectrumOnEmpty: config.spectrumOnEmpty
    readonly property alias workspaceCount: config.workspaceCount
    readonly property alias workspaceMax: config.workspaceMax
    readonly property alias autoHideAnimation:config.autoHideAnimation
    readonly property alias autoHideShowDuration:config.autoHideShowDuration
    readonly property alias autoHideHideDuration:config.autoHideHideDuration
    readonly property alias autoHideDelay:config.autoHideDelay
    readonly property alias autoHideTravel:config.autoHideTravel
    readonly property alias autoHideEdge:config.autoHideEdge
    readonly property alias barAutoHideSmart:config.barAutoHideSmart
    readonly property alias barAutoHide:config.barAutoHide
    readonly property alias windowAnimationSpeed:config.windowAnimationSpeed
    readonly property alias windowAnimationAmount:config.windowAnimationAmount
    readonly property alias windowAnimationBounce:config.windowAnimationBounce
    readonly property alias windowWorkspaceMotion:config.windowWorkspaceMotion
    readonly property alias windowShadowSharpness:config.windowShadowSharpness
    readonly property alias windowShadowOffsetX:config.windowShadowOffsetX
    readonly property alias windowShadowOffsetY:config.windowShadowOffsetY
    readonly property alias windowShadowUseAccent:config.windowShadowUseAccent
    readonly property alias setupTransitionStyle:config.setupTransitionStyle
    readonly property alias setupTransitionDuration:config.setupTransitionDuration
    readonly property alias setupTransitionDistance:config.setupTransitionDistance
    readonly property alias presetLibraryCarousel:config.presetLibraryCarousel
    readonly property alias documentLibraryRows:config.documentLibraryRows
    readonly property alias documentLibraryMotion:config.documentLibraryMotion
    readonly property alias documentLibraryMotionDuration:config.documentLibraryMotionDuration
    readonly property alias workspaceBackAndForth: config.workspaceBackAndForth
    readonly property alias wallpaperRandomTransitions: config.wallpaperRandomTransitions
    readonly property alias workspaceMode: config.workspaceMode
    readonly property alias workspaceStyle: config.workspaceStyle
    readonly property alias motionScale: config.motionScale
    readonly property alias motionCurve: config.motionCurve
    readonly property alias animationPreset: config.animationPreset
    readonly property alias windowShadow: config.windowShadow
    readonly property alias windowShadowRange: config.windowShadowRange
    readonly property alias windowShadowIntensity: config.windowShadowIntensity
    readonly property alias barShadow: config.barShadow
    readonly property alias barShadowRange: config.barShadowRange
    readonly property alias barShadowIntensity: config.barShadowIntensity
    readonly property alias barShadowSharpness:config.barShadowSharpness
    readonly property alias barShadowOffsetX:config.barShadowOffsetX
    readonly property alias barShadowOffsetY:config.barShadowOffsetY
    readonly property alias barShadowUseAccent:config.barShadowUseAccent
    readonly property alias settingsScrollSpeed:config.settingsScrollSpeed
    readonly property alias macGlassNautilus:config.macGlassNautilus
    readonly property alias macGlassFileDialogs:config.macGlassFileDialogs
    readonly property alias macGlassFileDialogOpacity:config.macGlassFileDialogOpacity
    readonly property alias dockShadow: config.dockShadow
    readonly property alias widgetShadow: config.widgetShadow
    readonly property alias macGlassBarProfile:config.macGlassBarProfile
    readonly property alias macGlassProfileTarget:config.macGlassProfileTarget
    readonly property alias macGlassRefraction: config.macGlassRefraction
    readonly property alias macGlassBlur: config.macGlassBlur
    readonly property alias macGlassTint: config.macGlassTint
    readonly property alias macGlassShine: config.macGlassShine
    readonly property alias macGlassLive: config.macGlassLive
    readonly property alias macGlassWindows: config.macGlassWindows
    readonly property alias macGlassSettings: config.macGlassSettings
    readonly property alias macGlassTerminal: config.macGlassTerminal
    readonly property alias lockFieldMaterial: config.lockFieldMaterial
    readonly property alias lockGlassRefraction: config.lockGlassRefraction
    readonly property alias lockGlassBlur: config.lockGlassBlur
    readonly property alias lockGlassTint: config.lockGlassTint
    readonly property alias lockGlassShine: config.lockGlassShine
    readonly property alias windowGlass: config.windowGlass
    readonly property alias surfaceStyle: config.surfaceStyle
    readonly property alias liquidOpacity: config.liquidOpacity
    readonly property alias liquidOldOpacity: config.liquidOldOpacity
    readonly property alias liquidRefraction: config.liquidRefraction
    readonly property alias liquidBlur: config.liquidBlur
    readonly property alias liquidTint: config.liquidTint
    readonly property alias liquidShine: config.liquidShine
    readonly property alias desktopGround: config.desktopGround
    readonly property alias barSides: config.barSides
    readonly property alias wallpaperTransition: config.wallpaperTransition
    readonly property alias wallpaperTransitionDuration:config.wallpaperTransitionDuration
    readonly property alias themePickerDesign:config.themePickerDesign
    readonly property alias wallpaperPickerDesign:config.wallpaperPickerDesign
    readonly property alias wallpaperStartPage:config.wallpaperStartPage
    readonly property alias wallpaperFilterByTheme:config.wallpaperFilterByTheme
    readonly property alias wallpaperThemeLinks:config.wallpaperThemeLinks
    readonly property alias themeLastWallpapers:config.themeLastWallpapers
    readonly property alias wallpaperCloseAfterApply:config.wallpaperCloseAfterApply
    readonly property alias wallpaperColorsAfterTransition:config.wallpaperColorsAfterTransition
    readonly property alias greeting: config.greeting
    readonly property alias fontFamily: config.fontFamily
    readonly property alias fontMono: config.fontMono
    readonly property alias notificationTimeout: config.notificationTimeout
    readonly property alias compositor: config.compositor
    readonly property alias keyboard: config.keyboard
    readonly property alias displays: config.displays
    readonly property alias keys: config.keys
    readonly property alias launcherPrefixes: config.launcherPrefixes
    readonly property alias cursorColor: config.cursorColor
    readonly property alias cursorSize: config.cursorSize
    readonly property alias shakeToFind: config.shakeToFind
    readonly property alias nightLight: config.nightLight
    readonly property alias nightTemperature: config.nightTemperature
    readonly property alias lidPolicy: config.lidPolicy
    readonly property alias idleLock: config.idleLock
    readonly property alias idleScreen: config.idleScreen
    readonly property alias idleSuspend: config.idleSuspend
    readonly property alias language: config.language

    // ── LAUNCHER PREFIXES ───────────────────────────────────────────────────
    //
    // The first character that selects each launcher mode. Stored as
    // overrides keyed by mode id, so a new mode needs no new key.
    readonly property var launcherPrefixDefaults: ({
        calculate: "=", desk: ">", windows: "@", timer: "!", clipboard: "'",
        emoji: ":"
    })

    function launcherPrefix(id: string): string {
        const kept = config.launcherPrefixes ?? ({})
        const chosen = kept[id]
        if (typeof chosen === "string" && chosen.length === 1)
            return chosen
        return root.launcherPrefixDefaults[id] ?? ""
    }

    function setLauncherPrefix(id: string, sigil: string): void {
        const next = Object.assign({}, config.launcherPrefixes ?? ({}))
        if (sigil === "" || sigil === root.launcherPrefixDefaults[id])
            delete next[id]
        else
            next[id] = sigil
        config.launcherPrefixes = next
    }

    readonly property var clockFormats: [
        { id: "HH:mm", label: "24-hour", sample: "17:04" },
        { id: "hh:mm AP", label: "12-hour", sample: "05:04 PM" }
    ]

    // ── BAR LAYOUT ──────────────────────────────────────────────────────────
    //
    // The style is how the bar is drawn; the layout is what is on it, as two
    // lists either side of the island. Changing style keeps the layout.
    readonly property var barStyles: [
        { id: "grouped", label: "Grouped",    note: "The workspaces, the island and the modules together in the middle." },
        { id: "spread",  label: "Spread",     note: "The workspaces at one edge, the modules at the other, the island between them." },
        { id: "island",  label: "One island", note: "Everything inside a single capsule." },
        { id: "bezel",   label: "Bezel",      note: "A band across the whole top edge, with the island dropping out of its middle." }
    ]

    // The island is cut into the top edge: chosen, or the bezel, which is
    // always cut in.
    readonly property bool notched: config.islandAttached || config.barStyle === "bezel"

    // Used while `barLeft`/`barRight` are null. `workspaces` is the strip,
    // `tray` the applications' icons and `split` starts a new capsule; none is
    // a module. The tray is not drawn while it is empty.
    readonly property var barDefaults: ({
        left: ["workspaces"],
        right: ["tray", "notifications", "network", "bluetooth", "volume", "battery"]
    })

    // An entry is a bare id, or `{ id, shape, figure, when }` when the piece
    // has its own look. Empty shape/figure follow `chipShape`/`chipFigure`;
    // `when: "running"` shows it only while active (`ModuleService.shows`).
    //
    // Copied out: JsonAdapter returns lists as Qt sequences, which fail
    // `Array.isArray` and would be mutated in place by a caller's filter.
    function barItems(side: string): var {
        const kept = side === "left" ? config.barLeft : config.barRight
        const list = kept ? Array.from(kept) : root.barDefaults[side]
        return list.filter(entry => !["pet","board"].includes(typeof entry === "string" ? entry : entry.id)).map(entry => typeof entry === "string"
            ? { id: entry, shape: "", figure: "", when: "" }
            : { id: entry.id, shape: entry.shape ?? "", figure: entry.figure ?? "",
                when: entry.when ?? "" })
    }

    function barZone(side: string): var {
        return root.barItems(side).map(item => item.id)
    }

    function onBar(id: string): bool {
        return root.barZone("left").indexOf(id) >= 0
            || root.barZone("right").indexOf(id) >= 0
    }

    // Drops splits at either end or next to another split, which would draw
    // an empty capsule.
    function tidy(items: var): var {
        const out = []
        const idOf = item => typeof item === "string" ? item : item.id
        for (const item of items) {
            if (idOf(item) === "split" && (out.length === 0 || idOf(out[out.length - 1]) === "split"))
                continue
            out.push(item)
        }
        while (out.length > 0 && idOf(out[out.length - 1]) === "split")
            out.pop()
        return out
    }

    // Accepts ids or items; stores a bare id for any piece without its own
    // look.
    function setBarZone(side: string, items: var): void {
        const packed = root.tidy(items).map(item => {
            if (typeof item === "string")
                return item
            if ((item.shape ?? "") === "" && (item.figure ?? "") === "" && (item.when ?? "") === "")
                return item.id
            const out = { id: item.id }
            if (item.shape)
                out.shape = item.shape
            if (item.figure)
                out.figure = item.figure
            if (item.when)
                out.when = item.when
            return out
        })
        root.set(side === "left" ? "barLeft" : "barRight", packed)
    }

    // What may sit beside the time on the island while it runs. A module left
    // out still works on the bar; it just doesn't take a side of the island.
    // `privacy` is the microphone, camera or screen in use, which has no
    // module. A recording is always there, and is not on this list.
    readonly property var besideDefaults: ["privacy", "timer", "media", "machine"]
    // Every one the settings offer; the workspace is off until chosen.
    readonly property var besideChoices: ["privacy", "timer", "media", "machine", "workspace"]

    // A kept list predates any choice added since: one that is on by default
    // joins it once, and stays off if it is taken off after that. A list kept
    // before this was remembered saw the first four.
    function welcomeActivities(): void {
        const kept = config.islandActivities
        if (!kept)
            return
        const seen = config.islandActivitiesSeen
            ? Array.from(config.islandActivitiesSeen) : ["privacy", "timer", "media", "workspace"]
        const fresh = root.besideDefaults.filter(id => seen.indexOf(id) < 0 && Array.from(kept).indexOf(id) < 0)
        if (fresh.length === 0 && seen.length === root.besideChoices.length)
            return
        config.islandActivities = Array.from(kept).concat(fresh)
        config.islandActivitiesSeen = root.besideChoices.slice()
    }

    function beside(id: string): bool {
        const kept = config.islandActivities
        return (kept ? Array.from(kept) : root.besideDefaults).indexOf(id) >= 0
    }

    function setBeside(id: string, on: bool): void {
        const kept = config.islandActivities
        const next = (kept ? Array.from(kept) : root.besideDefaults.slice())
            .filter(other => other !== id)
        if (on)
            next.push(id)
        root.set("islandActivities", next)
        root.set("islandActivitiesSeen", root.besideChoices.slice())
    }

    // ── CHIPS ───────────────────────────────────────────────────────────────
    //
    // One shape and one figure mode for the whole bar; a piece may override
    // both (`barItems`). A module without a gauge draws its symbol in either
    // shape (`ModuleService.shapeOf`).
    readonly property var chipShapes: [
        { id: "icon", label: "Icon", note: "The symbol alone, small." },
        { id: "ring", label: "Ring", note: "The gauge, in a circle." }
    ]

    // How the workspace strip draws a workspace: shapes first, then the
    // number written out.
    readonly property var workspaceStyles: [
        { id: "dots", label: "Dots" },
        { id: "bars", label: "Bars" },
        { id: "rings", label: "Rings" },
        { id: "numbers", label: "Numbers" },
        { id: "roman", label: "Roman" },
        { id: "kanji", label: "Kanji" },
        { id: "greek", label: "Greek" }
    ]

    readonly property var chipFigures: [
        { id: "off",   label: "No",       note: "No figure beside it" },
        { id: "hover", label: "On hover", note: "The figure opens under the pointer" },
        { id: "on",    label: "Always",   note: "The figure always beside it" }
    ]

    // No writes until the file has been read: `onAdapterUpdated` writes the
    // whole adapter, so an early `set` would overwrite every stored preference
    // with defaults. A second shell instance sharing the file makes the race
    // easy to hit. Refused writes are dropped, not queued, since a queue could
    // replay over a file another instance has written since.
    property bool arrived: false

    // No settings file existed at startup; `ProfileService` then starts on
    // the first bundled profile.
    property bool fresh: false

    function moduleRadius(id: string, fallback: real): real {
        return Math.max(0, Math.min(64, config.moduleRounding?.[id] ?? fallback))
    }

    function setSharedModuleColour(role:string,value:var):void {root.set("moduleColourSync",Object.assign({},root.moduleColourSync,{[role]:value}))}
    function setShellColour(id:string,role:string,value:string):void {
        const next=root.copy(root.shellColours)||{}
        next[id]=Object.assign({},next[id]||{},{[role]:value})
        root.set("shellColours",next)
    }
    function setSidebarTextColour(id:string,value:string):void {root.set("sidebarTextColours",Object.assign({},root.sidebarTextColours,{[id]:value}))}
    function setSidebarColour(id:string,value:string):void {
        root.set("sidebarColours",Object.assign({},root.sidebarColours,{[id]:value}))
    }
    function workspaceSize(style: string, key: string, fallback: real): real {
        return config.workspaceDimensions?.[style]?.[key] ?? fallback
    }
    function setWorkspaceSize(style: string, key: string, value: real): void {
        const next = root.copy(config.workspaceDimensions) || {}
        next[style] = Object.assign({}, next[style] || {}, { [key]: value })
        root.set("workspaceDimensions", next)
    }

    property bool batchedWrite:false
    function set(key: string, value: var): void {
        if (config[key] === undefined) {
            console.warn("Unknown setting:", key)
            return
        }
        if (!root.arrived) {
            console.warn("Settings not read yet; refusing to write", key)
            return
        }
        if(config[key] === value)return
        if(value !== null && typeof value === "object" && JSON.stringify(config[key]) === JSON.stringify(value))return
        root.batchedWrite=["shellSpring","shellBezier","windowMotion","moduleAnimations","moduleColourSync","nautilusFrost","settingsFrost","terminalFrost","moduleElements","moduleAppearance","moduleRounding","islandChipSettings","launcherStyle","settingsDesign","macGlassBarProfile","workspaceDimensions","workspaceGlowRange","workspaceGlowIntensity","workspaceGlowSpread","shellColours","sidebarColours","sidebarTextColours","macGlassRefraction","macGlassEdgeWidth","macGlassSpread","macGlassCentreStrength","macGlassFlow","notchCornerRadius","notchRoundingPower","notchShoulderRoundingPower","notchShoulderRadius","notchOffsetX"].includes(key)
        config[key] = value
    }

    // ── PROFILES ────────────────────────────────────────────────────────────
    //
    // A profile is every key except these, which belong to the machine or
    // the person: kept across switches, left out of exports and untouched by
    // Reset. The recorder and capture entries are last-used state.
    readonly property var machineKeys: [
        "wallpaperStartPage", "themeLastWallpapers", "wallpaperThemeLinks", "wallpaperFilterByTheme", "savedColourThemes", "savedShellMotionPresets", "displays", "lidPolicy", "workspaceMode", "workspaceBackAndForth",
        "barHoverExtraWidth", "barHoverExtraHeight", "barHoverEnlargeBackgroundOnly", "barHoverEnlargeAmount", "barHoverHighlight", "barClickHoverEnlarge", "islandSummary", "islandSummaryMode", "islandHoverLayout", "islandHoverDesign", "islandHoverTopLeft", "islandHoverTopRight", "islandHoverDatePosition", "islandHoverDateFollowBar", "islandHoverMediaAutoHide", "islandHoverOpenDelay", "islandHoverCloseDelay", "barAutoHide", "barAutoHideSmart", "autoHideAnimation", "autoHideShowDuration", "autoHideHideDuration", "autoHideDelay", "autoHideTravel", "autoHideEdge", "setupTransitionStyle", "setupTransitionDuration", "setupTransitionDistance", "presetLibraryCarousel", "documentLibraryRows",
        "userName", "userAvatar", "language", "keyboard", "weatherPlace", "githubUser", "markets",
        "emojiTone",
        "doNotDisturb", "nightLight", "nightTemperature", "barHidden", "desktopHidden",
        "gameMode",
        "cameraEnabled", "cameraEffect", "cameraReactions",
        "recorderAudio", "captureShape", "captureKind"
    ]

    // A Store never read from disk: its initialisers are the defaults.
    readonly property Store pristine: Store {}

    // Enumerating a QML object yields its properties, methods and `objectName`.
    readonly property var storedKeys: {
        const out = []
        for (const key in root.pristine) {
            if (key !== "objectName" && typeof root.pristine[key] !== "function")
                out.push(key)
        }
        return out
    }

    readonly property var profileKeys:
        root.storedKeys.filter(key => root.machineKeys.indexOf(key) < 0)

    // Type tag for matching a loaded value against its default. Lists come
    // back as Qt sequences (see `barItems`), so test the JSON form.
    function shapeOf(value: var): string {
        if (value === null || value === undefined)
            return "null"
        if (typeof value !== "object")
            return typeof value
        return JSON.stringify(value).charAt(0) === "[" ? "list" : "map"
    }

    // Whether `value` can replace this key's default. A null default (an
    // unarranged layout) accepts null, a list or a map; numbers must be finite.
    function accepts(key: string, value: var): bool {
        const wanted = root.shapeOf(root.pristine[key])
        const given = root.shapeOf(value)
        if (wanted === "null")
            return given === "null" || given === "list" || given === "map"
        if (given === "number" && !Number.isFinite(value))
            return false
        return wanted === given
    }

    // Deep copy as plain data, so callers never hold the store's objects.
    function copy(value: var): var {
        return value === undefined ? null : JSON.parse(JSON.stringify(value))
    }

    // Every profile key, from `values` where valid and from the defaults
    // otherwise, so a switch never inherits the previous profile's values.
    function complete(values: var): var {
        const given = values ?? ({})
        const out = {}
        for (const key of root.profileKeys) {
            const taken = Object.prototype.hasOwnProperty.call(given, key)
                && root.accepts(key, given[key])
            out[key] = root.copy(taken ? given[key] : root.pristine[key])
        }
        return out
    }

    // The active profile, as plain data.
    function snapshot(): var {
        const out = {}
        for (const key of root.profileKeys)
            out[key] = root.copy(config[key])
        return out
    }

    // Applies a profile in one turn so the file is written once (`saver`).
    // Hyprland keeps the previous profile's values until reloaded; the caller
    // handles that (`CompositorService.reassert`).
    function adopt(values: var): bool {
        if (!root.arrived) {
            console.warn("Settings not read yet; refusing to adopt a profile")
            return false
        }
        const next = root.complete(values)
        for(const key of root.profileKeys) {
            if(config[key]===next[key])continue
            if(next[key]!==null && typeof next[key]==="object" && JSON.stringify(config[key])===JSON.stringify(next[key]))continue
            config[key]=next[key]
        }
        return true
    }

    // Resets the active profile to defaults; machine keys are kept.
    function reset(): void {
        root.adopt({})
    }

    // A new desk types in the machine's layout, the one systemd-localed wrote
    // for the console and the login screen, rather than in input.lua's `us`.
    // Read into the first write, so nothing can reload over it.
    readonly property FileView machineKeyboard: FileView {
        path: "/etc/X11/xorg.conf.d/00-keyboard.conf"
        blockLoading: true
        printErrors: false
    }

    function machineLayout(): var {
        const text = root.machineKeyboard.text()
        const layout = /^\s*Option\s+"XkbLayout"\s+"([^"]+)"/m.exec(text)
        if (!layout)
            return ({})
        const found = { "input:kb_layout": layout[1] }
        const options = /^\s*Option\s+"XkbOptions"\s+"([^"]*)"/m.exec(text)
        const switches = options ? options[1].split(",").filter(o => o.startsWith("grp:")) : []
        if (switches.length > 0)
            found["input:kb_options"] = switches.join(",")
        return found
    }

    // ── STORAGE ─────────────────────────────────────────────────────────────

    readonly property FileView file: FileView {
        path: `${root.stateDirectory}/settings.json`
        watchChanges: true
        blockLoading: true

        // This small preferences file is committed synchronously so an older
        // async save cannot feed stale data back into newer slider values.
        blockWrites: true
        onFileChanged: reload()
        // Deferred to the end of the turn: calling `writeAdapter()` twice in
        // one turn reads back a stale `var` value and loses the second
        // change. Coalescing also means one write per turn (`adopt()`).
        onAdapterUpdated: saver.restart()
        onLoaded: {
            root.arrived = true
            root.welcomeActivities()
            // A ground named "frosted" is read as glass, and an empty one,
            // which followed the bar's, takes the bar's.
            for (const key of ["surfaceStyle", "desktopGround", "dockGround"])
                if (config[key] === "frosted")
                    config[key] = "glass"
            for (const key of ["desktopGround", "dockGround"])
                if (config[key] === "")
                    config[key] = config.surfaceStyle
            // The dock shared the bar's shadow before it had its own.
            if (!/"dockShadow"/.test(file.text()))
                config.dockShadow = config.barShadow
            // One island spanning the screen is the bezel now.
            if (/"barFullWidth":\s*true/.test(file.text()) && config.barStyle === "island")
                config.barStyle = "bezel"
        }
        // First run: write the defaults, which then count as read.
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.fresh = true
                config.keyboard = root.machineLayout()
                root.arrived = true
                writeAdapter()
            }
        }

        // Slider drags update the scene immediately; commit once the drag pauses.
        readonly property Timer saver: Timer {
            interval: root.batchedWrite?80:0
            onTriggered: root.file.writeAdapter()
        }

        Store {
            id: config
        }
    }

    // ── SCHEMA ──────────────────────────────────────────────────────────────
    //
    // Declared once, instantiated twice: `config` is read from the file and
    // `pristine` holds the defaults.
    component Store: JsonAdapter {
        property string clockFormat: "HH:mm"
        property bool clockShowsDate: false
        property bool clockShowsSeconds: false
        property var moduleRounding: ({})
        property var moduleAppearance: ({})
        property var moduleColourSync:({enabled:false,respectIndividual:false,foreground:"accent",accent:"accent",muted:"accent",background:"",foregroundBrightness:100,accentBrightness:100,mutedBrightness:70,backgroundOpacity:100})
        property var shellColours:({})
        property var sidebarColours:({})
        property var sidebarTextColours:({})
        property var savedColourThemes:[]
        property string nautilusWindowMode:"tiled"
        property string nautilusIconStyle:"reference"
        property real notchShoulderRoundingPower:2
        property real notchRoundingPower:2
        property int workspaceInactiveBrightness:100
        property int workspaceOccupiedBrightness:100
        property int notchCornerRadius:-1
        property int notchShoulderRadius:12
        property int notchOffsetX:0
        property bool powerSaverBarEffects:true
        property bool chipFollowModules:true
        property int chipHideDuration:150
        property int chipShowDuration:230
        property int chipReturnDelay:35
        property int macGlassRefractionRange:180
        property string macGlassRefractionMode:"edges"
        property int macGlassEdgeWidth:12
        property int macGlassSpread:8
        property int macGlassCentreStrength:18
        property int macGlassFlow:0

        property var moduleElements: ({})
        property bool islandChipsEnabled: false
        property var islandChipSettings: ({})
        property int islandChipGap: 12
        property var workspaceDimensions: ({})
        property string cursorStyle: "tahoe"
        property string notesBodyFont: ""
        property int maximizedBarGap: 15
        property bool lockIslandEnabled: false
        property bool barEntryEnabled:true
        property bool barEntryOnUnlock:true
        property string barEntryAnimation:"fade"
        property int barEntryDuration:500
        property int barEntryHold:140
        property int barEntryUnlockLead:160
        property string lockIslandTransition:"fade"
        property int lockIslandTransitionDuration:280
        property int lockIslandOpenHold:100
        property int lockIslandCloseDuration:220
        property string lockAnimation: "fade"
        property string lockUnlockMovement:"follow"
        property int lockUnlockDuration:0
        property int lockAnimationDuration: 600
        property int lockAnimationSpeed: 100
        property string lockAnimationMovement: "smooth"
        property int lockAnimationBounciness: 40
        property int lockAnimationRebounds: 2
        property int lockSlideDistance: 110
        property bool islandBattery: false
        property bool islandBatteryGlow:false
        property int islandBatteryFillOpacity:100
        property int islandBatteryEmptyOpacity:24
        property int islandBatteryTipOpacity:32
        property string islandBatteryIconStyle: "new"
        property string islandBatteryMode: "both"
        property string islandBatteryPosition: "right"
        property bool islandWorkspaces: false
        property bool islandWorkspacesGlow: false
        property int workspaceGlowRange:24
        property int workspaceGlowIntensity:80
        property int workspaceGlowSpread:115
        property string islandWorkspacesPosition: "left"
        property bool islandInternet: false
        property string islandInternetPosition: "right"
        property string islandInternetStyle: "bars"
        property int islandClockSize: 18
        property string islandLayout: "balanced"
        property int islandPillWidth: 150
        property int islandPaddingLeft: 12
        property int islandPaddingRight: 12
        property int islandWorkspacesOffset: 0
        property int islandInternetOffset: 0
        property int islandBatteryOffset: 0
        property int islandWorkspacesScale: 100
        property int islandInternetScale: 100
        property int islandBatteryScale: 100
        property bool islandBluetooth: false
        property string islandBluetoothPosition: "right"
        property int islandBluetoothOffset: 0
        property int islandBluetoothScale: 100
        property bool islandSpeaker: false
        property bool islandSpeakerPercent: false
        property string islandSpeakerPosition: "right"
        property int islandSpeakerOffset: 0
        property int islandSpeakerScale: 100

        // Capsule height and distance from the top edge. Every other bar
        // metric derives from `barHeight`.
        property int barScale:100
        property string settingsWindowMode:"floating"
        property int barHeight: 32
        property int barMargin: 16

        // A notch flush with the top edge instead of a floating capsule.
        property bool islandAttached: false
        property int islandFloatingGap: 12

        property int barSideMargin: 18

        // A bar on every screen, or only on the one being worked on. The
        // surface is on every screen either way: this is whether it paints.
        property bool barEverywhere: true

        // Zen: the bar off the screen and its band given to the windows; the
        // island still comes down for what it has to show.
        property bool barHidden: false

        // Every screen's four corners rounded off in black.
        property bool screenCorners: false

        // Game mode: no animations, blur, shadow or glass on the compositor,
        // over whatever the rest of the settings say.
        property bool gameMode: false

        // Four shadows, one per layer: Hyprland's under the windows, the
        // shell's under the bar, the dock and the desk's widgets.
        property bool windowShadow: false
        property int windowShadowRange: 14
        property int windowShadowIntensity: 50
        property bool barShadow: false
        property int barShadowRange: 8
        property int barShadowIntensity: 50
        property int barShadowSharpness:3
        property int barShadowOffsetX:0
        property int barShadowOffsetY:0
        property bool barShadowUseAccent:false
        property int settingsScrollSpeed:150
        property bool macGlassNautilus:false
        property bool macGlassFileDialogs:false
        property int macGlassFileDialogOpacity:78
        property bool dockShadow: false
        property bool widgetShadow: false

        // hyprglass. Dimmed in the settings when the plugin is not built;
        // `CompositorService` pushes it at login and after every reload.
        property var macGlassBarProfile:({})
        property string macGlassProfileTarget:"windows"
        property int macGlassRefraction: 100
        property int macGlassBlur: 5
        property int macGlassTint: 42
        property int macGlassShine: 30
        property bool macGlassLive: false
        property bool macGlassWindows: false
        property bool macGlassSettings: false
        property bool macGlassTerminal: false
        property string lockFieldMaterial: "classic"
        property int lockGlassRefraction: 80
        property int lockGlassBlur: 5
        property int lockGlassTint: 35
        property int lockGlassShine: 30
        property bool windowGlass: false

        // The island's and the bar's ground: "classic" solid black,
        // "glass", the terminal's ground over the compositor's blur, or
        // "liquid", Hyprglass refraction; "liquid-old", the earlier QML frost.
        property string surfaceStyle: "classic"
        property int liquidOpacity: 38
        property int liquidOldOpacity: 40
        property int liquidTint: 82
        property int liquidShine: 52
        property int liquidRefraction: 35
        property int liquidBlur: 20

        // The desktop widgets' ground, as above.
        property string desktopGround: "classic"

        // The bar's sides: "capsule", each group in a capsule, or "bare",
        // the icons on the wallpaper. The one-capsule style has its band.
        property string barSides: "capsule"

        // Row id from `WallpaperService.transitions`; `random` picks anew on
        // each change.
        property string wallpaperTransition: "wipe"
        property int wallpaperTransitionDuration:120
        property string themePickerDesign:"reference"
        property string wallpaperPickerDesign:"carousel"
        property string wallpaperStartPage:"wallpaper"
        property bool wallpaperFilterByTheme:true
        property var wallpaperThemeLinks:({})
        property var themeLastWallpapers:({})
        property bool wallpaperCloseAfterApply:false
        property bool wallpaperColorsAfterTransition:false

        // Row id from `ThemeService.greetings`; `random` is picked by `fa` on
        // each run.
        property string greeting: "random"

        // One of `barStyles`.
        property string floatingBarSurface:"grey"
        property string barStyle: "grouped"

        // Ids either side of the island; null means `barDefaults`.
        property var barLeft: null
        property var barRight: null

        // Hovering the island opens the glance; a click still opens the
        // control centre.
        property bool islandSummary: true
        property string islandSummaryMode: "click"
        property bool islandHoverDateFollowBar:true
        property string islandHoverDatePosition:"bottom"
        property string islandHoverTopLeft:"media"
        property string islandHoverTopRight:"notifications"
        property int barHoverExtraWidth:0
        property int barHoverExtraHeight:0
        property bool barHoverEnlargeBackgroundOnly:true
        property real barHoverEnlargeAmount:4.5
        property bool barHoverHighlight:false
        property bool barClickHoverEnlarge:false
        property var islandHoverLayout:({"mediaEnabled": false, "mediaWidth": 280, "mediaHeight": 56, "mediaX": 0, "mediaY": 60, "mediaTitleSize": 13, "mediaArtistSize": 11, "mediaArtSize": 40, "mediaControls": false, "followBarStyle": true, "enabled": false, "width": 760, "height": 96, "clockSize": 24, "dateSize": 12, "dateGap": 8, "clockX": 0, "clockY": 0, "leftPadding": 28, "rightPadding": 28, "leftY": 14, "rightY": 14, "headerY": 6, "headerHeight": 26, "headerSize": 12, "headerIconSize": 14, "headerLeftX": 28, "headerRightX": 28, "workspaceScale": 100, "signalScale": 100, "batteryScale": 100, "workspaceWidth": 6, "workspaceHeight": 12, "workspaceInactiveWidth": 5, "workspaceInactiveHeight": 8, "workspaceGap": 4})
        property string islandHoverDesign:"classic"
        property bool islandHoverMediaAutoHide:true
        property int islandHoverOpenDelay:110
        property int islandHoverCloseDelay:260
        property int shellBounceStrength:100
        property int shellBounceCycles:100
        property int shellMovement:100
        property int shellFadeDuration:100
        property int shellExpandDuration:380
        property string shellCloseMode:"parallel"
        property int shellShapeSpring:45
        property int shellBounceDamping:100
        property int shellFadeDistance:8
        property int shellZoomAmount:3
        property var shellBezier:({enabled:false,x1:20,y1:80,x2:20,y2:100})
        property var windowMotion:({openSpeed:100,closeSpeed:100,moveSpeed:100,workspaceSpeed:100,fadeSpeed:100,openStyle:"preset",closeStyle:"preset",curve:"preset"})
        property var savedShellMotionPresets:[]
        property var shellSpring:({mode:"spring",wideDuration:230,verticalDuration:310,enabled:false,damping:82,openFrequency:28,closeFrequency:24,panelFrequency:22,openDuration:330,closeDuration:340,panelDuration:380,switchDuration:330,itemStagger:18,movingItems:true,contentDelay:45,contentFade:75,restFade:50,closeContentFade:85})
        property var moduleAnimations:({all:{engine:"easing",followShell:true,closeParallel:true,exactDuration:false,openDuration:380,closeDuration:380,customCurve:false,bezierX1:20,bezierY1:80,bezierX2:20,bezierY2:100,preset:"theme",speed:100,curve:"preset",axisDelay:18,contentFade:100,closeSpeed:100,matchClosing:true,barItemsBounce:false,barItemsBounceStrength:35,barItemsBounceDuration:420,hoverCloseSpeed:100,hoverCloseBounce:45,closePreset:"smooth",closeCurve:"preset",closeFade:100,swapDuration:110}})

        // The playing track's lyrics, looked up on lrclib.net while
        // something on screen shows them.
        property bool lyrics: true

        // Null means `besideDefaults`.
        property var islandActivities: null
        // The choices there were when that list was kept, so one added since
        // can join it once (`welcomeActivities`).
        property var islandActivitiesSeen: null

        // One of `chipShapes` and one of `chipFigures`.
        property string chipShape: "icon"
        property string chipFigure: "on"

        property bool emojiFollowsLauncher:false
        property var settingsDesign:({})
        property var launcherStyle:({})
        property int launcherResults: 9

        // Order with an empty query: `recent` ranks by launch count with
        // decay; otherwise alphabetical.
        property string launcherOrder: "recent"

        // Fit the island to the number of results instead of a fixed-height
        // list. Off by default: a list that holds still is easier to aim at.
        // `launcherResults` caps it either way.
        property bool launcherFits: false

        // Skin tone for emoji that have one: 0 is the default yellow, 1 to 5
        // light to dark. The person's, so it stays with the machine.
        property int emojiTone: 0

        // ── CAMERA ──────────────────────────────────────────────────
        //
        // Off takes the virtual camera away from every program.
        property bool cameraEnabled: true

        // One of `CameraService.effects`.
        property string cameraEffect: "natural"

        // The gestures that set off a reaction, by `CameraService.reactions` id.
        property var cameraReactions: ["thumbsup", "heart", "peace", "thumbsdown", "horns", "ok"]

        // ── CLIPBOARD ───────────────────────────────────────────────
        //
        // Off stops the watcher, not just the list.
        property bool clipboardHistory: true

        // Payloads are stored as separate files, so the index stays small.
        property int clipboardKeep: 200

        property bool clipboardImages: true

        // Password-manager copies are never stored regardless
        // (`clipboard.py`).
        property bool clipboardWipeOnLock: false

        // Enough to make text unreadable, no more.
        property string lockDesign: "original"
        property string centreDesign: "original"
        property int lockClockSize: 168
        property int lockDateSize: 22
        property int lockClockTop: 54
        property int lockClockOpacity: 100
        property int lockDateOpacity: 78
        property int lockClockShadow: 45
        property bool lockShowsDate: true
        property string lockTimeFormat: "HH:mm"
        property string lockFont: "rounded"
        property string lockInk: "white"
        property int lockAvatarSize: 46
        property int lockAccountBottom: 12
        property int lockProfileGap: 8
        property int lockPromptGap: 32
        property int lockNameSize: 11
        property int lockFieldWidth: 210
        property int lockFieldHeight: 32
        property int lockFieldOpacity: 14
        property int lockFieldBorderOpacity: 34
        property int lockDim: 18
        property int lockExtraBlur: 75
        property bool lockStatus: true
        property bool lockHint: true
        property string lockIdleHint: "Touch ID or Enter Password"
        property string lockPlaceholder: "Enter Password"
        property string lockBackdrop:"wallpaper"
        property int lockVibrance:42
        property int lockBlur: 32

        // "stacked", hours over minutes as the login screen draws them, or
        // "inline".
        property string lockClock: "stacked"

        // What is playing on the lock: "lyrics" (the player and its lyrics),
        // "player" or "off"; and behind it, the "cover" blurred or the
        // "desktop" as without music.
        property string lockMusic: "lyrics"
        property string lockMusicGround: "cover"

        // Empty means read from the system: the passwd full name and
        // `~/.face` (`AccountService`).
        property string userName: ""
        property string userAvatar: ""

        // Persisted so silent mode survives a restart.
        property bool doNotDisturb: false

        property bool recorderAudio: false

        // The capture surface reopens on its last shape and kind. The
        // destination is not stored: it resets to saving a file.
        property string captureShape: "region"
        property string captureKind: "photo"

        // Note bodies in the handwriting font instead of the UI font.
        property bool notesHandwriting: true

        // Show edge note decks only on empty workspaces.
        property bool deckOnEmpty: false

        // Show the spectrum only on empty workspaces.
        property bool spectrumOnEmpty: false


        // Dots always shown, and the total number of workspaces. Workspaces
        // past `workspaceCount` still show while occupied.
        property int workspaceCount: 5
        property int workspaceMax: 10
        // `shared`: every screen shares the same workspaces. `screen`: each
        // has ten of its own, the main screen 1–10 and the rest after it.
        property string autoHideAnimation:"slide-fade"
        property int autoHideShowDuration:340
        property int autoHideHideDuration:280
        property int autoHideDelay:850
        property int autoHideTravel:8
        property int autoHideEdge:4
        property bool barAutoHideSmart:false
        property bool barAutoHide:false
        property int windowAnimationSpeed:100
        property int windowAnimationAmount:100
        property int windowAnimationBounce:100
        property string windowWorkspaceMotion:"preset"
        property int windowShadowSharpness:3
        property int windowShadowOffsetX:0
        property int windowShadowOffsetY:0
        property bool windowShadowUseAccent:false
        property string setupTransitionStyle:"fade"
        property int setupTransitionDuration:280
        property int setupTransitionDistance:20
        property bool presetLibraryCarousel:true
        property int documentLibraryRows:2
        property string documentLibraryMotion:"slide"
        property int documentLibraryMotionDuration:180
        property bool workspaceBackAndForth: false
        property var wallpaperRandomTransitions: null
        property string workspaceMode: "shared"
        // How the strip draws each workspace: a shape (`dots`, `bars`, `rings`)
        // or its number written out (`numbers`, `roman`, `kanji`, `greek`).
        property string workspaceStyle: "dots"

        // Percentage. 100 is the designed speed; 0 disables animation.
        property int motionScale: 100

        // Named in Theme.easingCurves.
        property string motionCurve: "OutCubic"

        // Hyprland's animation preset, from Motion.presets (the two above
        // are the shell's own). `CompositorService` pushes it at startup and
        // after every reload; `animations.lua` deliberately has no preset.
        property string animationPreset: "macos"

        property string fontFamily: "Inter, Cantarell, SF Pro Text, sans-serif"
        property string fontMono: "JetBrainsMono Nerd Font Mono, monospace"

        property int notificationTimeout: 5000

        // ── COMPOSITOR ──────────────────────────────────────────────────
        //
        // Hyprland options changed from the settings window, keyed by
        // option path. Absent keys are left to the Lua config. The option
        // whitelist lives in `compositor.py`.
        property var compositor: ({})

        // The keyboard's own options (`input:kb_*`), kept apart from
        // `compositor` because the keyboard is the machine's, not the desk's.
        property var keyboard: ({})

        // ── DISPLAYS ────────────────────────────────────────────────────
        //
        // Arrangements keyed by the set of connected monitors (their
        // descriptions, sorted and joined). Without one, Hyprland's `auto`
        // applies.
        //
        //   <profile> primary   description of the screen the shell's
        //                       surfaces go on; "" means Quickshell's
        //                       first, where an unset
        //                       `PanelWindow.screen` lands anyway
        //             monitors  per description: mode, position, scale,
        //                       transform, mirror, vrr, disabled — each
        //                       optional, absent when unchanged
        //
        // Fields are defined by `monitors.py`.
        property var displays: ({})

        // ── KEYS ────────────────────────────────────────────────────────
        //
        // A combination per bind in `hypr/keybinds.lua`, keyed by its
        // description; "" leaves it unbound. Empty until the first change,
        // then complete. `ShortcutService` writes it to keys.tsv, which the
        // Lua config reads.
        property var keys: ({})

        // Launcher sigil overrides, keyed by mode id; absent means the
        // default in `launcherPrefixDefaults`.
        property var launcherPrefixes: ({})

        // ── DESKTOP ─────────────────────────────────────────────────────
        //
        // Desktop widgets in placement order; a module may appear more than
        // once:
        //
        //   key      this widget — "clock-1"; a row without one is keyed
        //            by its module on the way in
        //   id       the module, the same id the catalogue uses
        //   screen   the monitor's description; absent means the main screen
        //   col, row the square its top left corner is on
        //   family   "2x2", "4x2", "4x4" or "8x2" — which face it wears
        //   theme    "modern", "analogue" or "sticker"; absent means the
        //            desktop's
        //   style    how its capsule is drawn; absent means the desktop's
        //   opacity  how solid it is; absent means the desktop's
        //   note     for a notes widget, which note; absent means the
        //            front of the deck
        //
        // Or a deck of notes on a screen edge:
        //
        //   key      "notes-2"
        //   id       "notes"
        //   screen   as above
        //   edge     "left", "right" or "bottom"
        //   notes    the note keys on it, in order along the edge
        //   along    where on the edge, 0 to 1 from its first corner
        //   takesNew true on the one deck new notes land on
        property var desktopWidgets: []

        // The theme for widgets without their own, from
        // `DesktopService.themes`. Colours always come from the palette, and
        // the capsule's ground is the island's (`surfaceStyle`).
        property string desktopTheme: "modern"

        // Capsule opacity in percent; below 100 the desktop layer's blur
        // rule (`windowrules.lua`) shows through. Widgets may override it.
        property int desktopOpacity: 100

        // Every widget off the picture for a while; arranging shows them.
        property bool desktopHidden: false

        // ── CONTROL CENTRE ──────────────────────────────────────────────
        //
        // The top row's doors before `centreTop`, ids from
        // `ControlsService.doors`; read only as that row's default.
        property var centreButtons: null

        // The top row: `{ left, right }`, session action and door ids in
        // order. Null is the session's actions left and the doors above
        // right; two empty sides are no row at all.
        property var centreTop: null

        // The grid's columns and rows; 0 is the default the default layout
        // fills.
        property int centreColumns: 0
        property int centreRows: 0

        // The blocks on the control centre's grid, one row each:
        //
        //   id    the block, from `ControlsService.catalogue`
        //   col   which column its top left cell is in
        //   row   and which row
        //   size  "2x3": columns by rows, one of the sizes the block offers
        //
        // Null means the default layout.
        property var centreBlocks: null

        // Toggles on the tile block, in order, from
        // `ControlsService.toggleCatalogue`. Null is the default six;
        // overflow becomes a second page.
        property var centreToggles: null

        // ── DOCK ────────────────────────────────────────────────────────
        //
        // An empty dock is not drawn, so enabling it by default costs
        // nothing on a fresh install.
        property bool dockEnabled: true

        // Pinned desktop entry ids, in order. Name, icon and command are
        // read from the entry.
        property var dockPinned: []

        // Any edge but the top, which is the bar's.
        property string dockEdge: "bottom"

        property string dockAlignment: "center"

        // Every other dock metric derives from the icon size.
        property int dockIconSize: 44

        // The icons swell under the pointer and the neighbours make room.
        property bool dockMagnify: true

        // Percent; the compositor blurs behind the layer.
        property int dockOpacity: 100

        // The capsule's ground, as `surfaceStyle`.
        property string dockGround: "classic"

        // kitty's ground, as `surfaceStyle`.
        property bool nautilusBlur:false
        property bool settingsBlur:false
        property var nautilusFrost: ({opacity:35,frost:50,passes:2,grain:4,saturation:100,brightness:100,contrast:100,tint:8,tintColor:"#ffffff"})
        property var settingsFrost: ({opacity:35,frost:50,passes:2,grain:4,saturation:100,brightness:100,contrast:100,tint:8,tintColor:"#ffffff"})
        property var terminalFrost: ({opacity:35,frost:50,passes:2,grain:4,saturation:100,brightness:100,contrast:100,tint:8,tintColor:"#ffffff"})
        property string terminalGround: "glass"

        // Also show running applications that aren't pinned.
        property bool dockRunning: true

        // A dock on every screen, or only on the one being worked on.
        property bool dockEverywhere: true

        property bool dockAutohide: false

        // Launcher button at the start of the row.
        property bool dockLauncher: true

        // Anything wttr.in accepts: a city, postcode or airport code. Empty
        // lets wttr.in geolocate by IP, which can be tens of kilometres off.
        property string weatherPlace: ""

        // GitHub user for the contributions widget; empty draws nothing.
        property string githubUser: ""

        // The markets widget's pairs, BASE/QUOTE or a coin alone (in US
        // dollars), separated by commas.
        property string markets: "BTC, ETH, EUR/USD"

        // One of `PetService.styles`: how the pet is drawn, everywhere it is
        // drawn.
        property string petStyle: "creature"

        // Idle timeouts in minutes, 0 = never; all off by default.
        // `IdleService` runs one monitor per value.
        property int idleLock: 0
        property int idleScreen: 0
        property int idleSuspend: 0

        // Kelvin. Persisted, unlike keep-awake, so a restart comes back
        // warm. `SunsetService` drives hyprsunset.
        property bool nightLight: false
        property int nightTemperature: 4000

        // Closing the lid with another screen connected: `off` disables the
        // panel and moves its workspaces, `keep` leaves it on, `system`
        // defers to logind. The result is written into the display profile
        // so it survives hotplug. With no other screen, logind decides.
        property string lidPolicy: "off"

        // "palette" follows the accent; otherwise a fixed #rrggbb. Built and
        // applied by compositor.py.
        property string cursorColor: "palette"
        property int cursorSize: 24

        // hypr-dynamic-cursors' shake magnification (`shake.enabled`).
        property bool shakeToFind: true

        // Translations live in `theme/Tr.qml`; missing strings fall back to
        // English.
        property string language: "en"
    }
}
