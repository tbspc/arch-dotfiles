// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   D Y N A M I C   I S L A N D                                            │
// │   morphing centre capsule · hosts every island layer                     │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import Quickshell
import "../../theme"
import "../../services"
import "../island"
import "../modules"
import "../../components"
import "../../components/SpringMotion.js" as SpringMotion
import "../../components/MotionTrace.js" as MotionTrace
import "../../lock"

// One capsule that changes shape to fit whatever it shows. IslandState picks
// the layer, this sizes the capsule for it, and a Loader swaps the contents;
// the shape animates while the contents cross-fade.
PowerRectangle {
    id: root
    roundingPower:SettingsService.notched?Theme.notchRoundingPower:2

    // Settings is a separate window owned by `shell.qml`; the request is
    // passed up.
    signal settingsRequested()

    Connections {
        target:ThemeService
        function onThemeRequested(themeId:string):void {
            const palette=SettingsService.savedColourThemes.find(t=>t.id===themeId)||Palettes.byId(themeId)
            if(SettingsService.wallpaperCloseAfterApply && palette?.wallpaper && root.expanded && ["appearance","palette"].includes(islandState.openPanel))root.close()
        }
    }
    Connections {
        target:WallpaperService
        function onPickerCloseRequested():void {
            if(root.expanded&&(islandState.openPanel==="appearance"||islandState.openPanel==="palette"))root.close()
        }
    }
    readonly property alias state: islandState
    readonly property bool expanded: (islandState.expanded&&root.closeStage!=="parallel") || root.closeStage === "replace"
    property string closeStage:""
    readonly property bool closing:root.closeStage!==""
    readonly property bool closingHover:root.closeStage==="hover"
    readonly property bool closingToRest:root.closingHover||root.closeStage==="parallel"
    readonly property bool bannerActive:SettingsService.islandHoverDesign!=="classic"&&(islandState.layer===islandState.layerSummary||islandState.openPanel==="summary")
    readonly property real hoverCollapseProgress:root.bannerActive?1-Math.max(0,Math.min(1,(root.height-root.layerSizes.modules.height-root.notchPad)/Math.max(1,ModuleService.summaryHeight-root.layerSizes.modules.height))):0
    property bool openedFromRest:false
    property bool switchingPanel:false
    readonly property bool referenceMotion:root.motionSettings.engine==="spring"
    readonly property var referenceSettings:Object.assign({},SettingsService.pristine.shellSpring,root.motionSettings.spring||SettingsService.shellSpring)
    property string panelTransitionKind:"panel-open"
    readonly property bool tracedMotion:root.referenceMotion&&root.referenceSettings.mode==="traced"
    readonly property string referenceKind:root.closing?(root.closingHover?"hover-close":"panel-close"):root.summarising?"hover-open":root.panelTransitionKind
    readonly property var referenceTrace:MotionTrace.profile(root.referenceKind,root.referenceSettings.moduleVideo===true)
    readonly property real referenceFrequency:root.closing?root.referenceSettings.closeFrequency:root.summarising?root.referenceSettings.openFrequency:root.referenceSettings.panelFrequency
    readonly property real referenceSeconds:geometry.timeline*root.morphDuration/1000
    property real panelEntranceProgress:1
    property int panelEntranceDuration:380
    readonly property real panelEntranceSeconds:root.panelEntranceProgress*root.panelEntranceDuration/1000
    NumberAnimation {
        id:panelEntrance
        target:root;property:"panelEntranceProgress";from:0;to:1
        duration:root.panelEntranceDuration;easing.type:Easing.Linear
        onFinished:root.openedFromRest=false
    }
    readonly property bool openingRestVisible:root.referenceMotion&&root.openingMotion&&root.openedFromRest&&root.expanded&&panelEntrance.running&&root.panelEntranceSeconds*1000<root.referenceSettings.restFade
    readonly property real referenceOpenRestAlpha:root.openingRestVisible?1-Math.min(1,root.panelEntranceSeconds*1000/Math.max(1,root.referenceSettings.restFade)):0
    readonly property real incomingContentAlpha:root.referenceMotion&&root.openingMotion&&!root.bannerActive?Math.max(0,Math.min(1,(root.panelEntranceSeconds*1000-Math.max(root.openedFromRest?root.referenceSettings.restFade:0,root.referenceSettings.contentDelay))/Math.max(1,root.referenceSettings.contentFade))):1
    readonly property var referenceLayout:({trace:root.tracedMotion?root.referenceTrace.width||root.referenceTrace.height:null,active:root.referenceMotion&&geometry.running&&root.referenceSettings.movingItems,seconds:root.referenceSeconds,duration:root.morphDuration,damping:root.referenceSettings.damping,frequency:root.referenceFrequency,stagger:root.referenceSettings.itemStagger,closing:root.closing,fromWidth:geometry.fromWidth,toWidth:geometry.targetWidth,fromHeight:geometry.fromHeight,toHeight:geometry.targetHeight,progress:Math.abs(geometry.targetWidth-geometry.fromWidth)>1?(root.width-geometry.fromWidth)/(geometry.targetWidth-geometry.fromWidth):Math.abs(geometry.targetHeight-geometry.fromHeight)>1?(root.height-geometry.fromHeight)/(geometry.targetHeight-geometry.fromHeight):1})
    readonly property bool closeGeometryHeld:root.closeStage==="out"||root.closeStage==="replace"
    readonly property bool closeRestVisible:root.closeStage==="out"||root.closeStage==="replace"||root.closeStage==="shrink"||root.closingHover||root.closeStage==="parallel"
    property real closeUiAlpha:1
    property real closeHeldWidth:0
    property real closeHeldHeight:0
    property real closeHeldRadius:0
    property string closeMotionId:""
    readonly property var motionSettings:SettingsService.moduleMotion(root.closing?root.closeMotionId:root.summarising?"summary":root.designId||"bar")
    readonly property var openingPreset:SettingsService.moduleAnimationPresets.find(p=>p.id===root.motionSettings.preset)||SettingsService.moduleAnimationPresets[0]
    readonly property real motionPace:Theme.motion===0?0:root.motionSettings.followShell?Theme.motion:1
    readonly property int morphDuration:geometry.duration
    readonly property real morphOvershoot:geometry.overshoot
    readonly property var morphBezier:geometry.bezierCurve
    readonly property int baseAnimationDuration:root.referenceMotion?(root.closing?(!root.closingHover&&root.referenceSettings.moduleCloseDuration>0?root.referenceSettings.moduleCloseDuration:root.referenceSettings.closeDuration):root.summarising?root.referenceSettings.openDuration:root.switchingPanel?(root.panelTransitionKind==="wide-switch"?root.referenceSettings.wideDuration:root.panelTransitionKind==="vertical-switch"?root.referenceSettings.verticalDuration:root.referenceSettings.switchDuration):root.referenceSettings.panelDuration):root.motionSettings.followShell?SettingsService.shellExpandDuration:root.motionSettings.exactDuration?(root.closing&&!root.motionSettings.matchClosing?root.motionSettings.closeDuration:root.motionSettings.openDuration):root.closing?root.closingPreset.duration:root.openingMotion?root.openingPreset.duration:380
    readonly property var expansionCurve:{
        if(root.tracedMotion)return root.referenceTrace.width||root.referenceTrace.height
        if(root.referenceMotion)return SpringMotion.curve(root.baseAnimationDuration*root.motionPace,root.referenceSettings.damping,root.referenceFrequency)
        const options=root.motionSettings.followShell?SettingsService.shellBezier:root.motionSettings
        if(root.motionSettings.followShell?!options.enabled:!options.customCurve)return []
        const prefix=root.motionSettings.followShell?"":"bezier"
        const keys=prefix?["bezierX1","bezierY1","bezierX2","bezierY2"]:["x1","y1","x2","y2"]
        return keys.map(key=>Number(options[key])/100).concat([1,1])
    }
    readonly property bool openingMotion:!root.closing&&(root.expanded||root.summarising)
    readonly property var closingPreset:root.motionSettings.matchClosing?root.openingPreset:SettingsService.moduleAnimationPresets.find(p=>p.id===root.motionSettings.closePreset)||root.openingPreset
    readonly property int closingEasing:root.motionSettings.matchClosing?(root.motionSettings.followShell&&root.openingPreset.id==="theme"&&root.motionSettings.curve==="preset"?Theme.easing:root.openingEasing):Theme.easingTypeOf(root.motionSettings.closeCurve==="preset"?root.closingPreset.curve:root.motionSettings.closeCurve)
    readonly property real closingSpeed:root.motionSettings.matchClosing?root.motionSettings.speed:root.motionSettings.closeSpeed
    readonly property string closingProfile:root.closingPreset.id==="width-first"?"height-first":root.closingPreset.id==="height-first"?"width-first":root.closingPreset.id
    readonly property int openingEasing:Theme.easingTypeOf(root.motionSettings.curve!=="preset"?root.motionSettings.curve:root.openingPreset.curve)
    readonly property int restRevealDuration:Math.round(root.motionSettings.swapDuration*root.motionPace)
    readonly property var barBounceOptions:SettingsService.moduleMotion("bar")
    BarContentBounce {
        id:barBounce
        enabled:root.barBounceOptions.barItemsBounce&&!LockMotionService.desktopAnimating&&!LockService.pendingLock&&Theme.motion>0
        amplitude:8*root.barBounceOptions.barItemsBounceStrength/100
        duration:Math.round(root.barBounceOptions.barItemsBounceDuration*(root.barBounceOptions.followShell?Theme.motion:root.motionPace>0?1:0))
    }
    function cancelClose():void {
        closeSequence.stop()
        parallelContentFade.stop()
        root.closeStage=""
        root.closeUiAlpha=1
        root.restFaceSync.restart()
    }
    function showRestBeforeShrink():void {
        root.closeStage="replace"
        islandState.close()
        islandState.summary=false
        root.landing=true
        root.syncRestFace()
        barBounce.restart()
    }
    Connections {
        target:LockService
        function onPendingLockChanged():void {if(LockService.pendingLock&&root.closing)root.close()}
    }
    onActiveChanged:if(!root.active&&root.closing)root.close()
    NumberAnimation {
        id:parallelContentFade
        target:root;property:"closeUiAlpha";to:0
        duration:root.referenceMotion?Math.round(root.referenceSettings.closeContentFade*root.motionPace):Math.min(Math.round(root.morphDuration*.6),Math.round(140*root.motionPace*root.motionSettings.closeFade/100*(root.motionSettings.followShell?SettingsService.shellFadeDuration/100:1)))
        easing.type:Easing.OutCubic
    }
    SequentialAnimation {
        id:closeSequence
        NumberAnimation {target:root;property:"closeUiAlpha";to:0;duration:Math.round(140*root.motionPace*root.motionSettings.closeFade/100*(root.motionSettings.followShell?SettingsService.shellFadeDuration/100:1));easing.type:Easing.OutCubic}
        ScriptAction {script:{root.showRestBeforeShrink();root.closeStage="shrink";root.checkLanded()}}
    }
    Binding {
        target:LockService;property:"frameHold"
        value:root.expanded&&(islandState.openPanel==="controls"||islandState.openPanel==="session")
        when:root.active
        restoreMode:Binding.RestoreNone
    }

    // The island is drawn on every screen; one of them is the one being
    // worked on (`Bar.live`) and the rest are this shape at rest. Only the
    // live one opens anything, and `IslandState` is where that is enforced.
    property bool active: true

    // While a note is open the island is the note: paper to the edge, with no
    // rim or padding.
    readonly property bool paper: root.closeStage!=="parallel" && islandState.openPanel === "notes" && NotesService.opened !== ""
    readonly property var paperNote: NotesService.entry(NotesService.opened)
    readonly property color paperColor: NotesService.paperOf(root.paperNote ? root.paperNote.tint : "yellow")
    // A module detail brings its own margins.
    readonly property int panelPad: root.panelStyle.padding !== undefined ? root.panelStyle.padding : root.paper || islandState.openPanel === "summary"
        ? 0 : (islandState.openPanel === "module" ? Theme.cardInset : islandState.openPanel==="launcher"?LauncherService.style.padding:Theme.panelPadding)

    // For the bar: attached, the notch fillets have to light with the island.
    property real hoverContentScaleX:1
    property real hoverContentScaleY:1
    property bool externalHovered:false
    property bool summaryAllowed:true
    readonly property bool hovered: hover.hovered || root.externalHovered
    // Lit where a click does something: the clock at rest. Not at rest in the
    // one-capsule style, where the band and the island are one shape and
    // cannot light separately; not the glance, which is drawn on the black
    // with a player's controls of its own; not over panels, which have their
    // own controls; and not while `landing` from one.
    readonly property bool lit: (SettingsService.islandSummaryMode!=="click"||SettingsService.barHoverHighlight) && root.hovered && !root.hoverResumeBlocked && !root.closing && !root.landing
        && islandState.layer === islandState.layerModules && !root.hosted
    // Solid, a floating island at rest is a shade off the black; on glass it
    // is the capsules' ground, since a lighter veil reads as another material.
    property color surfaceColor: {
        const colourId=root.expanded?root.designId:"clock"
        if(Theme.hasModuleColour(colourId,"background"))return Theme.moduleColour(colourId,"background",Theme.islandGround)
        if (!Theme.solid)
            return root.lit ? Theme.islandGroundLit : Theme.islandGround
        if (root.lit)
            return Theme.islandSurfaceHover
        return SettingsService.notched ? Theme.islandGround : SettingsService.floatingBarSurface==="black"?"#000000":Theme.islandSurface
    }

    // The body and notch shoulders share one colour transition. Their
    // geometry stays fixed instead of lighting separate shapes out of sync.
    Behavior on surfaceColor {ColorAnimation {duration:Theme.durationFast}}

    // ── HOSTED ──────────────────────────────────────────────────────────────
    //
    // In the one-capsule style the bar draws a band behind the island and puts
    // the sides on it. This flag only changes what the island paints at rest;
    // once it shows more than the clock, the band morphs into it
    // (`Bar.islandTaken`).
    property bool hosted: false

    // Width left between the bar's ends (`Bar.panelRoom`). Unconstrained by
    // default, so an island without a bar gets the size it asks for.
    property int roomForPanel: 100000

    readonly property int overviewRows: Math.ceil(HyprlandService.maximum / 5)

    // ── PANEL SIZES ─────────────────────────────────────────────────────────
    //
    // Declared rather than measured: the island has to reach its final shape
    // before the panel inside it is loaded.
    readonly property var panelSizes: ({
        launcherpresets:root.presetCarouselSize,
        setuppresets:SettingsService.presetLibraryCarousel ? root.presetCarouselSize : {width:860,height:620},
        documents:{width:860,height:160+Math.max(1,Math.min(6,SettingsService.documentLibraryRows))*220},
        processes:{width:760,height:560},
        summary:    { width: ModuleService.summaryWidth, height: ModuleService.summaryHeight },
        controls:   { width: ControlsService.panelWidth, height: ControlsService.panelHeight },
        appearance: root.appearanceSize,
        palette:    SettingsService.themePickerDesign==="reference"?({width:808,height:224}):root.presetCarouselSize,
        barpresets: root.presetCarouselSize,
        stats:      { width: 940,  height: 614 },
        // Depends on the results when `launcherFits` is on.
        launcher:   { width: LauncherService.panelWidth,
                      height: LauncherService.panelHeight },
        wifi:       { width: 420,  height: 500 },
        // The control centre's volume, opened out.
        sound:      { width: AudioService.panelWidth, height: AudioService.panelHeight },
        microphone: { width: AudioService.panelWidth, height: AudioService.microphoneHeight },
        nightlight: { width: SunsetService.panelWidth, height: SunsetService.panelHeight },
        brightness: { width: BrightnessService.panelWidth, height: BrightnessService.panelHeight },
        bluetooth:  { width: 420,  height: 500 },
        session:    { width: 720,  height: 180 },
        // A program asking for root (`PolkitService`).
        auth:       { width: 460,  height: 236 },
        machines:   { width: 860,  height: 580 },
        // A row per server, from two to six before it scrolls.
        servers:    { width: ServersService.panelWidth, height: ServersService.panelHeight },
        screentime: { width: 940,  height: 614 },
        camera:     { width: CameraService.panelWidth, height: CameraService.panelHeight },
        // A row per creature, plus one for the next egg.
        // The shelf of cards, or the game being played at its own size.
        games:      GamesService.playing !== ""
            ? GamesService.panelSize(GamesService.playing)
            : { width: GamesService.shelfWidth, height: GamesService.shelfHeight },
        // Declared by their services, which the panels read back for layout.
        notes:      { width: NotesService.panelWidth, height: NotesService.panelHeight },
        tasks:      { width: TasksService.panelWidth, height: TasksService.panelHeight },
        // The key sheet's columns come from the compositor's bind list.
        keys:       { width: ShortcutService.sheetWidth, height: ShortcutService.sheetHeight },
        packages:   { width: PackagesService.panelWidth, height: PackagesService.panelHeight },
        module:     root.moduleSize,
        // A tray item's menu, a row per entry.
        tray:       { width: TrayService.menuWidth, height: TrayService.menuHeight },
        overview:   { width: 1560, height: 72 + root.overviewRows * 190 }
    })

    // One panel under two names (its two strips), so switching between them
    // slides instead of rebuilding. Fits five strip tiles and the large one.
    readonly property var appearanceSize: SettingsService.wallpaperPickerDesign==="gallery"?({width:1016,height:232}):SettingsService.wallpaperPickerDesign==="reference"?({width:808,height:224}):({ width: 940, height: 196 })
    // Unlike the wallpaper picker, preset carousels have a 40px toolbar.
    // Reserve the entire 125px selected tile plus footer, gap and edge clearance.
    readonly property var presetCarouselSize: ({width:940,height:2*Theme.panelPadding+40+Math.ceil(100*1.25)+12+Math.ceil(Theme.fontSizeRegular*1.4)+8})
    readonly property bool presetCarouselPanel:(["barpresets","launcherpresets","palette"].includes(islandState.openPanel)&&!(islandState.openPanel==="palette"&&SettingsService.themePickerDesign!=="carousel"))||(islandState.openPanel==="setuppresets"&&SettingsService.presetLibraryCarousel)

    // A module's detail, sized from the catalogue.
    readonly property var moduleSize: ModuleService.openSize(ModuleService.openId)

    readonly property string designId: islandState.openPanel === "module" ? ModuleService.openId : islandState.openPanel==="launcher"&&LauncherService.independentEmoji?"emoji":islandState.openPanel
    readonly property var panelStyle: SettingsService.moduleAppearance[root.designId] || ({})
    readonly property var nativePanelSize: root.panelSizes[islandState.openPanel] ?? root.panelSizes.controls
    readonly property var panelSize: ({
        width:Math.max(160,root.nativePanelSize.width*(root.panelStyle.widthScale??100)/100),
        height:Math.max(root.presetCarouselPanel?root.presetCarouselSize.height+2*Math.max(0,root.panelPad-Theme.panelPadding):64,root.nativePanelSize.height*(root.panelStyle.heightScale??100)/100)
    })

    // The bar's limit: the whole bar, or a spread bar's room between its
    // sides, which hide instead for a panel wider than that (`Bar.crowded`).
    readonly property int panelWidth: Math.min(root.panelSize.width, root.roomForPanel)
    readonly property int panelHeight: islandState.openPanel === "documents"
        ? Math.min(root.panelSize.height,Math.max(360,(QsWindow.window?.screen?.height||1080)-Theme.islandTopMargin-root.notchPad-24))
        : root.panelSize.height

    // One entry per layer: the capsule's size and the padding inside it.
    readonly property var layerSizes: ({
        modules:      { width: ModuleService.restWidth, height: Theme.capsuleHeight, padding: 0 },
        summary:      { width: ModuleService.summaryWidth,
                        height: ModuleService.summaryHeight,
                        padding: 0 },
        osd:          { width: 260, height: Theme.capsuleHeight, padding: 10 },
        // Taller when the notification brings buttons.
        notification: { width: NotificationService.toastWidth,
                        height: NotificationService.toastHeight,
                        padding: NotificationService.toastPadding },
        panel:        { width: root.panelWidth, height: root.panelHeight, padding: Theme.panelPadding }
    })

    readonly property var size: root.layerSizes[islandState.layer] ?? root.layerSizes.modules

    // Hover summaries and full panels use the same selected motion.
    // Bounces move their contents gently rather than stretching the capsule.
    property bool summaryCacheWarmed:false
    readonly property bool cachedSummaryActive:root.summaryCacheWarmed&&islandState.layer===islandState.layerSummary&&summaryCache.status===Loader.Ready
    readonly property bool summarising: islandState.layer === islandState.layerSummary
        || islandState.openPanel === "summary"
    readonly property int morphEasing:root.closingHover?(root.motionSettings.followShell?Theme.easing:root.motionSettings.hoverCloseBounce>0?Easing.OutBack:Easing.OutCubic)
        :root.closing?root.closingEasing
        :root.openingMotion&&(!root.motionSettings.followShell||root.openingPreset.id!=="theme"||root.motionSettings.curve!=="preset")?root.openingEasing
        :(root.expanded||root.summarising)?Theme.easing:Easing.OutCubic

    ViewMotion {
        id: entrance
        curve: root.referenceMotion?"OutCubic":root.motionSettings.followShell?SettingsService.motionCurve:root.openingPreset.id==="cinematic"?"FadeZoom":"FadeSoft"
        useShellSettings:root.motionSettings.followShell
        pace: root.motionPace*root.motionSettings.contentFade/(root.motionSettings.exactDuration?100:Math.max(25,root.motionSettings.speed))*(root.motionSettings.exactDuration?root.motionSettings.openDuration/380:1)
        ready:root.expanded ? (islandState.openPanel === "barpresets" ? presetCache.status === Loader.Ready : islandState.openPanel === "launcherpresets" ? launcherCache.status === Loader.Ready : islandState.openPanel === "setuppresets" ? libraryCache.status === Loader.Ready : panelLoader.status === Loader.Ready)
            : !root.summarising || collapsedLoader.status === Loader.Ready
        triggerKey: root.expanded ? "panel/" + islandState.openPanel
            : root.summarising ? "summary" : ""
    }

    // Off for the first frame so the island does not animate in from nothing
    // at startup.
    property bool animated: false

    // Attached, only the shape reaches up to the screen edge; the contents keep
    // their padding, so nothing already drawn moves.
    readonly property int notchPad: SettingsService.notched ? Theme.barTopMargin : 0

    readonly property var layerComponents: ({
        modules: restLayer,
        summary: summaryLayer,
        osd: osdLayer,
        notification: notificationLayer
    })

    readonly property var panelComponents: ({
        launcherpresets:launcherPresetPanel,
        setuppresets:unifiedPresetsPanel,
        documents:documentLibraryPanel,
        processes:processesPanel,
        summary: summaryLayer,
        controls: controlsPanel,
        appearance: appearancePanel,
        palette: appearancePanel,
        barpresets: barPresetsPanel,
        launcher: launcherPanel,
        wifi: networkDetail,
        sound: soundDetail,
        microphone: microphoneDetail,
        nightlight: nightLightDetail,
        brightness: brightnessDetail,
        bluetooth: bluetoothDetail,
        stats: statsPanel,
        overview: overviewPanel,
        session: sessionPanel,
        auth: authPanel,
        machines: machinesPanel,
        servers: serversPanel,
        screentime: screenTimePanel,
        camera: cameraPanel,
        games: gamesPanel,
        notes: notesPanel,
        tasks: tasksPanel,
        keys: keysPanel,
        packages: packagesPanel,
        module: moduleDetail,
        tray: trayMenu
    })

    function launcherPresetStatus():var {
        const item=launcherCache.item
        return {ready:LauncherPresetService.ready,saved:LauncherPresetService.saved.length,designs:LauncherPresetService.designs.length,
            open:islandState.openPanel,library:item?.library?.length??-1,index:item?.categoryIndex??-1,
            tiles:item?.activeStrip?Object.keys(item.activeStrip.tileObjects).length:0,stripReady:item?.activeStrip?.ready??false,
            count:item?.activeStrip?.count??-1,filter:item?.styleFilter??"",width:item?.width??0,height:item?.height??0}
    }
    property bool pendingLauncherOpen:false
    property real launcherReveal:islandState.expanded && islandState.openPanel === "launcherpresets" ? 1:0
    Behavior on launcherReveal {enabled:!LockService.preparingFrame;NumberAnimation {duration:root.expanded?Theme.durationMorph:Theme.durationFast;easing.type:Easing.OutCubic}}
    property bool pendingPresetOpen: false
    readonly property bool presetsReady: presetCache.status === Loader.Ready
    property real presetReveal: islandState.expanded && islandState.openPanel === "barpresets" ? 1 : 0
    Behavior on presetReveal {enabled:!LockService.preparingFrame; NumberAnimation { duration:root.expanded?Theme.durationMorph:Theme.durationFast; easing.type: Easing.OutCubic } }
    property bool pendingLibraryOpen:false
    property real libraryReveal:islandState.expanded && islandState.openPanel === "setuppresets" ? 1:0
    Behavior on libraryReveal {enabled:!LockService.preparingFrame;NumberAnimation {duration:root.expanded?Theme.durationMorph:Theme.durationFast;easing.type:Easing.OutCubic}}
    readonly property var libraryStyle:SettingsService.moduleAppearance.setuppresets||({})
    readonly property var librarySize:SettingsService.presetLibraryCarousel?root.presetCarouselSize:({width:860,height:620})
    readonly property real libraryPadding:root.libraryStyle.padding??Theme.panelPadding
    function prepareForLock():void {
        root.pendingPresetOpen=false;root.pendingLibraryOpen=false;root.pendingLauncherOpen=false
        root.hoverResumeBlocked=true
        dwell.stop();grace.stop();root.cancelClose();panelEntrance.stop()
        islandState.close();islandState.summary=false;root.landing=false
        ModuleService.close()
        geometry.snap();root.syncRestFace()
    }
    function open(panel: string): void {
        if(LockService.preparingFrame)return
        if(panel==="appearance"&&!["appearance","palette"].includes(islandState.openPanel)&&SettingsService.wallpaperStartPage==="palette")panel="palette"
        if (["pet","board"].includes(panel)) return
        const previousWidth=root.width,previousHeight=root.height
        root.openedFromRest=islandState.layer===islandState.layerModules
        root.switchingPanel=islandState.expanded&&islandState.openPanel!==panel
        if(root.closing)root.cancelClose()
        if(root.active && (panel==="controls"||panel==="session"))LockService.prefetchDesktop()
        if(islandState.openPanel==="barpresets" && panel!=="barpresets")presetCache.item?.deactivate()
        if (panel === "barpresets" && !root.presetsReady) {
            root.pendingPresetOpen=true
            return
        }
        if(panel === "setuppresets" && libraryCache.status !== Loader.Ready){root.pendingLibraryOpen=true;return}
        if(panel === "setuppresets")libraryCache.item.activate()
        if(panel === "launcherpresets" && launcherCache.status !== Loader.Ready){root.pendingLauncherOpen=true;return}
        if(panel === "launcherpresets")launcherCache.item.activate()
        if (panel === "barpresets") presetCache.item.activate()
        const changed=islandState.openPanel!==panel||!islandState.expanded
        islandState.open(panel)
        if(changed)root.panelTransitionKind=!root.switchingPanel?"panel-open":Math.abs(root.panelHeight-previousHeight)<Math.max(root.panelHeight,previousHeight)*.15?"wide-switch":Math.abs(root.panelWidth-previousWidth)<4?"vertical-switch":"switch"
        if(root.referenceMotion&&changed) {
            root.panelEntranceDuration=Math.max(1,root.morphDuration)
            panelEntrance.restart()
        }
    }

    function presetStatus():var {
        const item=presetCache.item
        return {expanded:root.expanded,panel:islandState.openPanel,width:root.width,height:root.height,ready:root.presetsReady,category:item?.categoryIndex??-1,index:item?.activeStrip?.current??-1,count:item?.activeStrip?.count??0,selected:item?.selected?.id??"",active:IslandPresetService.activeEntry()?.id??""}
    }
    function closeChip():void {QsWindow.window?.closeChipPanel()}
    function openChip(id:string):bool {return QsWindow.window?.openChipById(id)??false}
    function barVisibility():var {return {chipPanel:QsWindow.window?.chipPanelState||{},hover:{active:root.active,hovered:root.hovered,layer:islandState.layer,closing:root.closing,preparing:LockService.preparingFrame,pending:LockService.pendingLock,motion:LockMotionService.desktopAnimating,live:QsWindow.window?.live,grow:QsWindow.window?.clickHoverEnlarged,xScale:QsWindow.window?.clickHoverScaleX,yScale:QsWindow.window?.clickHoverScaleY,contentScaleX:root.hoverContentScaleX,contentScaleY:root.hoverContentScaleY},powerSaving:QsWindow.window?.powerSaving??false,efficientShadow:QsWindow.window?.efficientShadow??false,chips:QsWindow.window?.chipAnimationState||{},triggerLeft:QsWindow.window?.triggerLeft??0,triggerRight:QsWindow.window?.triggerRight??0,renderScale:root.parent?.scale??1,renderedWidth:root.width*(root.parent?.scale??1),renderedHeight:root.height*(root.parent?.scale??1),autoHide:SettingsService.barAutoHide,smart:SettingsService.barAutoHideSmart,overlap:QsWindow.window?.smartWindowOverlap??false,summaryMode:SettingsService.islandSummaryMode,preferredSummaryMode:SettingsService.preferredIslandSummaryMode,animation:SettingsService.autoHideAnimation,away:QsWindow.window?.away??false,revealed:QsWindow.window?.autoRevealed??false}}
    function libraryStatus():var {return {hoverLayout:summaryCache.item?.item?.motionMetrics?.()||{},hoverCache:{ready:root.summaryCacheWarmed,active:root.cachedSummaryActive,status:summaryCache.status},openingRestVisible:root.openingRestVisible,incomingContentAlpha:root.incomingContentAlpha,panelEntranceProgress:root.panelEntranceProgress,closeStage:root.closeStage,closeUiAlpha:root.closeUiAlpha,restFace:{visible:capsule.visible,contentOpacity:collapsedLoader.opacity,contentReady:collapsedLoader.status===Loader.Ready,contentHeight:collapsedLoader.height,opacity:capsule.opacity,target:root.restFaceOpacity,layer:islandState.layer,running:geometry.running,settled:root.settled},panel:islandState.openPanel,width:root.width,height:root.height,hoverProgress:root.hoverCollapseProgress,restY:capsule.y,restHeight:capsule.height,animation:{followShell:root.motionSettings.followShell,pace:root.motionPace,preset:root.openingPreset.id,closePreset:root.closingPreset.id,speed:root.motionSettings.speed,closeSpeed:root.closingSpeed,duration:geometry.duration,profile:geometry.profile},frames:geometry.frameStats(),ready:libraryCache.status===Loader.Ready,reveal:root.libraryReveal,contentOpacity:entrance.contentOpacity,view:(islandState.openPanel==="setuppresets"?libraryCache.item:panelLoader.item)?.navigationStatus?.()||{}}}
    function libraryNavigate(direction:string):void {(islandState.openPanel==="setuppresets"?libraryCache.item:panelLoader.item)?.browse?.(direction)}
    function libraryPreview():bool {return root.grabToImage(result=>result.saveToFile("/tmp/hyprland-library-preview.png"))}
    function presetStep(delta:int):void{presetCache.item?.step(delta)}
    Timer {id:wallpaperWorkResume;interval:150;onTriggered:root.wallpaperPickerClosing=false}
    property bool wallpaperPickerClosing:false
    Binding {target:WallpaperService;property:"pickerClosing";when:root.active;value:root.wallpaperPickerClosing;restoreMode:Binding.RestoreNone}
    function close(): void {
        root.pendingPresetOpen=false
        root.pendingLibraryOpen=false
        root.pendingLauncherOpen=false
        if(root.hoverMode&&islandState.expanded)root.hoverResumeBlocked=true
        if(LockService.pendingLock || !root.active || !root.animated || Theme.durationMorph<=0) {
            root.cancelClose()
            islandState.close()
            islandState.summary=false
            return
        }
        if(root.closing)return
        if(["appearance","palette"].includes(islandState.openPanel)){wallpaperWorkResume.stop();root.wallpaperPickerClosing=true}
        if(islandState.openPanel==="barpresets")presetCache.item?.deactivate()
        if(islandState.openPanel==="launcherpresets")launcherCache.item?.deactivate()
        if(!islandState.expanded && islandState.layer!==islandState.layerSummary) {
            islandState.close()
            return
        }
        // Hold the current shape while its contents are replaced. Only then
        // release the shape animation toward the normal bar dimensions.
        root.closeMotionId=root.summarising?"summary":root.designId||"bar"
        root.closeHeldWidth=root.width
        root.closeHeldHeight=root.height
        root.closeHeldRadius=root.radius
        root.closeUiAlpha=1
        if(islandState.layer===islandState.layerSummary&&SettingsService.islandHoverDesign!=="classic") {
            root.closeStage="hover"
            barBounce.restart()
            dwell.stop();grace.stop()
            return
        }
        if(root.motionSettings.closeParallel) {
            root.openedFromRest=false
            root.closeStage="parallel"
            root.syncRestFace()
            dwell.stop();grace.stop()
            parallelContentFade.restart()
            return
        }
        root.closeStage="out"
        root.syncRestFace()
        dwell.stop()
        grace.stop()
        closeSequence.restart()
    }

    // Shortcuts toggle: the same key opens and closes.
    function toggle(panel: string): void {
        if (islandState.openPanel === panel)
            root.close()
        else
            root.open(panel)
    }

    // Under everything the island holds; a note's paper is not glass.
    GlassSheen {
        shape: root
        visible: Theme.glass && !root.paper && !root.hosted
        edges: !SettingsService.notched
    }

    IslandState {
        id: islandState

        active: root.active
    }

    // Click mode opens a persistent panel. Hover mode restores the glance,
    // leaving icon hit targets available for their own module actions.
    HoverHandler {
        id: hover
    }

    // Closing a panel under a stationary pointer is not a new hover entry.
    property bool hoverResumeBlocked:false
    function releaseHoverOutside():void {
        if(!root.hovered&&!root.closing&&!root.expanded&&root.settled&&!LockService.locked&&!LockService.preparingFrame&&!LockMotionService.starting)
            root.hoverResumeBlocked=false
    }
    Timer{id:unlockHoverCheck;interval:32;onTriggered:root.releaseHoverOutside()}
    Connections{target:LockService;function onLockedChanged(){if(!LockService.locked)unlockHoverCheck.restart()}}
    Connections{target:LockMotionService;function onStartingChanged(){if(!LockMotionService.starting)unlockHoverCheck.restart()}}
    onHoverModeChanged:if(!root.hoverMode)root.hoverResumeBlocked=false
    readonly property bool hoverMode: SettingsService.islandSummaryMode === "hover"
    readonly property bool restBusy: islandState.layer === islandState.layerModules
        && (collapsedLoader.item?.busy ?? false)
    readonly property bool canSummarise: root.summaryAllowed&&!LockService.locked&&!LockService.preparingFrame&&!LockMotionService.starting&&root.hoverMode && !root.hoverResumeBlocked && root.active
        && !root.landing && !root.closing && !root.expanded && ModuleService.openId === ""
        && (islandState.layer === islandState.layerModules
            || islandState.layer === islandState.layerSummary)

    onCanSummariseChanged: {
        if (!root.canSummarise && !root.closing)
            islandState.summary = false
        else if (root.hovered && root.canSummarise)
            dwell.restart()
    }
    onRestBusyChanged: {
        if(root.hovered&&root.canSummarise&&!islandState.summary)dwell.restart()
    }

    Timer {
        id: dwell
        interval: SettingsService.islandHoverOpenDelay
        onTriggered: {
            if (root.hovered && root.canSummarise)
                islandState.summary = true
        }
    }
    Timer {
        id: grace
        interval: SettingsService.islandHoverCloseDelay
        onTriggered: {
            if (!root.hovered || !root.hoverMode) {
                if(islandState.layer===islandState.layerSummary)root.close()
                else islandState.summary=false
            }
        }
    }
    onHoveredChanged: {
            if (root.hovered) {
                grace.stop()
                if (root.canSummarise && !islandState.summary)
                    dwell.restart()
            } else {
                root.releaseHoverOutside()
                dwell.stop()
                grace.restart()
            }
    }

    property bool landing: false
    property string lastLayer: islandState.layerModules

    Connections {
        target: islandState
        function onLayerChanged(): void {
            if(!root.summarising&&summaryCache.status===Loader.Ready)root.summaryCacheWarmed=true
            if(islandState.layer===islandState.layerSummary&&!root.closing)barBounce.restart()
            if (islandState.layer === islandState.layerModules
                    && root.lastLayer !== islandState.layerModules) {
                root.landing = true
                Qt.callLater(root.checkLanded)
            }
            if (islandState.layer === islandState.layerModules
                    && root.lastLayer !== islandState.layerModules && !root.closeRestVisible)
                root.restFaceOpacity = 0
            root.lastLayer = islandState.layer
            root.restFaceSync.restart()
        }
    }

    onSettledChanged:{root.checkLanded();root.restFaceSync.restart();if(root.wallpaperPickerClosing){if(root.settled)wallpaperWorkResume.restart();else wallpaperWorkResume.stop()}}

    function checkLanded(): void {
        if(root.closeStage==="parallel"&&root.settled&&!geometry.running) {
            parallelContentFade.stop()
            islandState.close()
            islandState.summary=false
            root.restFaceOpacity=1
            root.closeStage=""
            root.closeUiAlpha=1
            if(root.active&&ModuleService.openHost==="island")ModuleService.close()
        }
        if(root.closingHover&&root.settled&&!geometry.running) {
            islandState.summary=false
            root.restFaceOpacity=1
            root.closeStage=""
            root.closeUiAlpha=1
        }
        if(root.closeStage==="shrink" && root.settled && !geometry.running) {
            if(root.active&&ModuleService.openHost==="island")ModuleService.close()
            root.closeStage=""
            root.closeUiAlpha=1
        }
        if (root.landing && !root.closing && root.settled && islandState.layer === islandState.layerModules)
            root.landing = false
        root.releaseHoverOutside()
    }

    TimedSize {
        id: geometry
        targetWidth:root.closeGeometryHeld?root.closeHeldWidth:root.closingToRest?root.layerSizes.modules.width:root.size.width
        targetHeight:root.closeGeometryHeld?root.closeHeldHeight:root.closingToRest?root.layerSizes.modules.height+root.notchPad:root.size.height+root.notchPad
        duration:LockService.pendingLock||!root.animated?0:Math.round(root.baseAnimationDuration*root.motionPace*(root.motionSettings.exactDuration?1:100/Math.max(25,root.closingHover?root.motionSettings.hoverCloseSpeed:root.closing?root.closingSpeed:root.motionSettings.speed)))
        easing:root.morphEasing
        overshoot:root.closingHover?1.70158*root.motionSettings.hoverCloseBounce/100:root.motionSettings.followShell?1.70158*SettingsService.shellShapeSpring/100:1.70158
        bezierCurve:root.expansionCurve
        heightBezierCurve:root.tracedMotion?root.referenceTrace.height||root.referenceTrace.width:[]
        profile:root.referenceMotion?"theme":root.closingHover?"theme":root.closing?root.closingProfile:root.openingMotion?root.openingPreset.id:"theme"
        axisDelay:root.motionSettings.axisDelay/100
        transitionKey:islandState.layer+"/"+islandState.openPanel
    }
    readonly property real morphWidthBudget:Math.max(geometry.fromWidth,geometry.targetWidth,width)
    readonly property real morphHeightBudget:Math.max(geometry.fromHeight,geometry.targetHeight,height)
    width: geometry.width
    height: geometry.height

    // True once the morph has reached its target size.
    readonly property bool settled: root.width === (root.closingToRest?root.layerSizes.modules.width:root.size.width)
        && root.height === (root.closingToRest?root.layerSizes.modules.height:root.size.height) + root.notchPad
    // A pill at capsule height, a rounded card once a module makes it taller.
    radius:root.bannerActive&&["reference-compact","reference-media"].includes(SettingsService.islandHoverDesign)?Math.min(root.height/2,SettingsService.moduleRadius("summary",28)*(1-root.hoverCollapseProgress)+Math.min(root.layerSizes.modules.height/2,SettingsService.notchCornerRadius>=0?SettingsService.notchCornerRadius:14)*root.hoverCollapseProgress):root.closeGeometryHeld?root.closeHeldRadius:!root.expanded && SettingsService.notched && SettingsService.notchCornerRadius>=0 ? Math.min(root.height/2,SettingsService.notchCornerRadius) : root.expanded
        ? SettingsService.moduleRadius(root.designId,
            islandState.openPanel !== "module" && islandState.openPanel !== "summary" ? Theme.radiusLarge : Math.min(root.height/2,Theme.radiusLarge+4))
        : SettingsService.moduleRadius("bar",SettingsService.islandChipsEnabled && IslandChipService.get("clock").style === "rounded" ? 10 : Math.min(root.height/2,Theme.radiusLarge+4))

    // In one capsule the band behind is the ground and covers the island
    // whole; a see-through island painted over it would double the glass.
    color: {
        if(!root.expanded && Theme.hasModuleColour("clock","background"))return Theme.moduleColour("clock","background",root.surfaceColor)
        if(root.expanded && Theme.hasModuleColour(root.designId,"background"))return Theme.moduleColour(root.designId,"background",root.paper?root.paperColor:Theme.islandGround)
        if (root.paper)
            return root.paperColor
        if(root.expanded&&islandState.openPanel==="launcher"&&LauncherService.style.surfaceTone!=="theme")return LauncherService.style.surfaceTone==="grey"?"#24262b":"#000000"
        if (root.hosted && !Theme.solid)
            return "transparent"
        if (Theme.solid && !root.expanded && SettingsService.islandChipsEnabled) {
            const surface = IslandChipService.get("clock").surface
            if (surface === "outline") return "transparent"
            if (surface === "glass") return Qt.rgba(1,1,1,0.14)
            if (surface === "solid") return "#080a0c"
        }
        return root.expanded ? Theme.moduleColour(root.designId,"background",Theme.islandGround) : Theme.moduleColour("clock","background",root.surfaceColor)
    }
    Behavior on color {enabled:root.closeStage==="parallel";ColorAnimation {duration:Math.min(120,root.morphDuration)}}
    border.color: Theme.islandRim

    // No hairline in the one-capsule style: at rest the island's edges run
    // through the band's interior, and while growing the band is the outer
    // edge. `Bar.qml` draws the outline over both. Attached, `Bar.qml` draws
    // it too, down the fillets and open along the screen edge.
    readonly property bool inBand: root.hosted
    border.width: root.paper || root.inBand || SettingsService.notched ? 0 : 1
    clip: true

    // Attached, the upper corners go square: the curve is added outside the
    // island by NotchFillet, flaring away from it rather than cutting into it.
    topLeftRadius: SettingsService.notched ? 0 : root.radius
    topRightRadius: SettingsService.notched ? 0 : root.radius

    Behavior on topLeftRadius {
        enabled: root.animated
        NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
    }
    Behavior on topRightRadius {
        enabled: root.animated
        NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
    }

    Component.onCompleted: root.animated = true

    // One animated value per axis; everything the bar draws around the island
    // (band, sides, fillets) is derived from it. None of those gets its own
    // Behavior: animating a sum whose other term changes every frame restarts
    // on every change and settles late.
    Behavior on radius {
        enabled: root.animated&&!LockService.preparingFrame
        ConfiguredNumberAnimation { duration: Math.min(root.morphDuration,Theme.durationMedium); curve:root.morphEasing;customCurve:root.morphBezier;spring:root.morphOvershoot }
    }

    // ── COLLAPSED ───────────────────────────────────────────────────────────

    // Non-staged returns still wait until their geometry settles. A normal
    // module close explicitly reveals the rest face before shrinking.
    readonly property bool restFaceFits:root.settled && !geometry.running
    onRestFaceFitsChanged:restFaceSync.restart()
    property real restFaceOpacity:1
    readonly property Timer restFaceSync:Timer {interval:0;onTriggered:root.syncRestFace()}
    function syncRestFace():void {
        if(root.closeRestVisible||root.openingRestVisible)root.restFaceOpacity=1
        else if(root.expanded || (islandState.layer===islandState.layerModules && !root.restFaceFits))root.restFaceOpacity=0
        else root.restFaceOpacity=1
    }
    onOpeningRestVisibleChanged:restFaceSync.restart()
    onExpandedChanged:{restFaceSync.restart();if(root.expanded){wallpaperWorkResume.stop();root.wallpaperPickerClosing=false}}
    Connections {
        target:geometry
        function onRunningChanged():void {root.checkLanded();root.restFaceSync.restart()}
    }

    // An Item, not a second rounded rectangle, so the hover light and the
    // click target cover the whole island.
    Item {
        id: capsule

        readonly property bool resting:root.expanded || islandState.layer===islandState.layerModules || root.closeStage==="parallel"
        width:resting?root.layerSizes.modules.width:parent.width
        height:resting?root.layerSizes.modules.height+root.notchPad:parent.height
        anchors.horizontalCenter:parent.horizontalCenter
        y:root.closeRestVisible||root.openingRestVisible?(parent.height-height)/2:0
        opacity:root.openingRestVisible?root.referenceOpenRestAlpha:root.restFaceOpacity*(root.referenceMotion&&root.closeStage==="parallel"?1-root.closeUiAlpha:1)*(root.closeStage==="out"&&islandState.layer===islandState.layerSummary?root.closeUiAlpha:1)
        // During staged closing the bar face is already present before the
        // shape shrinks, with its own normal width and vertical alignment.
        visible: opacity > 0 && (!root.expanded||root.closeRestVisible||root.openingRestVisible) && (root.closeRestVisible || islandState.layer !== islandState.layerModules || root.restFaceFits)

        Behavior on opacity {
            enabled:!root.referenceMotion&&root.animated&&!LockService.pendingLock&&!(root.closeStage==="out"&&islandState.layer===islandState.layerSummary)
                && (root.restFaceOpacity > 0 || islandState.layer !== islandState.layerModules)
            NumberAnimation { duration:root.restRevealDuration;easing.type:Easing.OutCubic }
        }

        // Declared before the layer so the layer's own controls (the media
        // play button) get clicks first; this still gets hover and the rest.
        MouseArea {
            id: capsuleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.ArrowCursor
            onClicked: root.open(root.hoverMode ? "controls" : "summary")
        }

        Padlock{anchors.centerIn:parent;z:40;visible:LockMotionService.desktopAnimating&&!islandState.expanded&&islandState.layer===islandState.layerModules;opened:LockMotionService.unlocking;animateLift:false;lift:LockMotionService.shackleLift;opacity:LockMotionService.symbolAlpha;tint:Theme.text;scale:.8}
        Item {
            id: middle

            anchors.fill: parent
            clip: true
            opacity:LockMotionService.desktopAnimating&&islandState.layer===islandState.layerModules?LockMotionService.alpha:1
            transform:[Scale{origin.x:middle.width/2;origin.y:middle.height/2;xScale:root.hoverContentScaleX;yScale:root.hoverContentScaleY},Scale{origin.x:middle.width/2;origin.y:middle.height/2;xScale:LockMotionService.desktopAnimating&&islandState.layer===islandState.layerModules?LockMotionService.contentScale:1;yScale:xScale},Translate{y:(LockMotionService.desktopAnimating&&islandState.layer===islandState.layerModules?LockMotionService.contentOffset:0)+(islandState.layer===islandState.layerModules?barBounce.offset:0)}]

            // Fades each new layer in.
            Loader {
                id: collapsedLoader
                ModuleElementStyler{id:barRestStyler;target:islandState.layer===islandState.layerModules||islandState.layer===islandState.layerPanel?collapsedLoader.item:null;moduleId:"bar"}
                onLoaded:barRestStyler.scan()

                // Keep the resting face at its resting size while the card
                // opens. Its parent fades it without reflow or reconstruction.
                active: true
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                // Use the layer's target height so the clock stays on its
                // normal midline while the larger panel shrinks around it.
                height:root.bannerActive?Math.max(0,root.height-root.notchPad):capsule.resting?root.layerSizes.modules.height:Math.max(0, root.size.height - 2 * root.size.padding)
                // Attached, the contents are centred in the full height,
                // matching the bar's raised midline (`Bar.laneY`).
                anchors.topMargin: (capsule.resting?0:root.size.padding) + root.notchPad / 2
                anchors.leftMargin: capsule.resting?0:root.size.padding
                anchors.rightMargin: capsule.resting?0:root.size.padding
                // Keep the resting face alive during a cached hover morph.
                sourceComponent:root.cachedSummaryActive?restLayer:root.layerComponents[islandState.layer]??restLayer
                visible:!root.cachedSummaryActive

                opacity:root.bannerActive?1:root.summarising?entrance.contentOpacity:1
                transform: [
                    Scale {
                        origin.x: collapsedLoader.width / 2
                        origin.y: collapsedLoader.height / 2
                        xScale: root.summarising ? entrance.stretchX : 1
                        yScale: root.summarising ? entrance.stretchY : 1
                    },
                    Translate { y: root.summarising ? entrance.offset : 0 }
                ]
                onSourceComponentChanged: {
                    fade.stop()
                    if (root.bannerActive) {
                        collapsedLoader.opacity = 1
                    } else if (root.summarising && entrance.special) {
                        entrance.restart()
                        collapsedLoader.opacity = Qt.binding(() => entrance.contentOpacity)
                    } else {
                        collapsedLoader.opacity = 1
                        // The capsule owns the return fade. A second fade on
                        // its newly loaded rest face can briefly blank icons.
                        if (islandState.layer !== islandState.layerModules && !root.expanded)
                            fade.restart()
                    }
                }

                NumberAnimation {
                    id: fade
                    target: collapsedLoader
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Theme.durationFast
                    easing.type: Theme.easing
                }
            }
            Loader {
                id:summaryCache
                onLoaded:if(!root.summarising)root.summaryCacheWarmed=true
                asynchronous:true
                active:root.active&&SettingsService.islandHoverDesign!=="classic"
                sourceComponent:summaryLayer
                anchors.fill:collapsedLoader
                visible:root.cachedSummaryActive
                enabled:visible
                opacity:root.bannerActive?1:entrance.contentOpacity
                transform:[
                    Scale {origin.x:summaryCache.width/2;origin.y:summaryCache.height/2;xScale:root.summarising?entrance.stretchX:1;yScale:root.summarising?entrance.stretchY:1},
                    Translate {y:root.summarising?entrance.offset:0}
                ]
            }
        }
    }

    // ── EXPANDED ────────────────────────────────────────────────────────────

    // A FocusScope, so one Escape handler covers every panel. A plain Item
    // holding focus here would take it from the launcher's search field; a
    // scope delegates inward, so the field keeps the keyboard and unhandled
    // keys bubble up here. Nothing inside sets `focus: true` for the same
    // reason: on the Loader it takes focus from the field a frame after the
    // field asks for it.
    FocusScope {
        id: panelScope
        opacity:root.closeUiAlpha*root.incomingContentAlpha
        enabled:!root.closing

        anchors.fill: parent
        clip: true
        focus: islandState.expanded

        Keys.onEscapePressed: root.close()

        Loader {
            id: presetCache
            ModuleElementStyler{target:presetCache.item;moduleId:"barpresets"}
            active: root.active
            asynchronous: true
            sourceComponent: barPresetsPanel
            anchors.horizontalCenter: parent.horizontalCenter
            y:Theme.panelPadding+root.notchPad
            width:Math.max(0,Math.min(root.presetCarouselSize.width,root.roomForPanel)-2*Theme.panelPadding)
            height:Math.max(0,root.presetCarouselSize.height-2*Theme.panelPadding)
            visible: root.presetReveal>0
            opacity: root.presetReveal
            transform:[
                Scale{origin.x:presetCache.width/2;origin.y:presetCache.height/2;xScale:root.expanded?entrance.stretchX:1;yScale:root.expanded?entrance.stretchY:1},
                Translate{y:root.expanded?entrance.offset:0}
            ]
            onLoaded: if(root.pendingPresetOpen){root.pendingPresetOpen=false;root.open("barpresets")}
        }

        Loader {
            id:launcherCache
            active:root.active
            asynchronous:true
            sourceComponent:launcherPresetPanel
            ModuleElementStyler {target:launcherCache.item;moduleId:"launcherpresets"}
            anchors.horizontalCenter:parent.horizontalCenter
            y:Theme.panelPadding+root.notchPad
            width:Math.max(0,Math.min(root.presetCarouselSize.width,root.roomForPanel)-2*Theme.panelPadding)
            height:Math.max(0,root.presetCarouselSize.height-2*Theme.panelPadding)
            visible:root.launcherReveal>0
            opacity:root.launcherReveal
            transform:[Scale{origin.x:launcherCache.width/2;origin.y:launcherCache.height/2;xScale:root.expanded?entrance.stretchX:1;yScale:root.expanded?entrance.stretchY:1},Translate{y:root.expanded?entrance.offset:0}]
            onLoaded:if(root.pendingLauncherOpen){root.pendingLauncherOpen=false;root.open("launcherpresets")}
        }
        // Reuse the library like the bar and launcher carousels. Hidden
        // previews do not animate; opening no longer constructs the whole UI.
        Loader {
            id:libraryCache
            active:root.active
            asynchronous:true
            sourceComponent:unifiedPresetsPanel
            ModuleElementStyler {target:libraryCache.item;moduleId:"setuppresets"}
            anchors.horizontalCenter:parent.horizontalCenter
            y:root.libraryPadding+root.notchPad
            width:Math.max(0,Math.min(root.librarySize.width*(root.libraryStyle.widthScale??100)/100,root.roomForPanel)-2*root.libraryPadding)
            height:Math.max(0,Math.max(SettingsService.presetLibraryCarousel?root.presetCarouselSize.height+2*Math.max(0,root.libraryPadding-Theme.panelPadding):0,root.librarySize.height*(root.libraryStyle.heightScale??100)/100)-2*root.libraryPadding)
            visible:root.libraryReveal>0
            opacity:root.libraryReveal*(root.libraryStyle.opacity??100)/100
            transform:[Scale{origin.x:libraryCache.width/2;origin.y:libraryCache.height/2;xScale:root.expanded?entrance.stretchX:1;yScale:root.expanded?entrance.stretchY:1},Translate{y:root.expanded?entrance.offset:0}]
            onLoaded:if(root.pendingLibraryOpen){root.pendingLibraryOpen=false;root.open("setuppresets")}
        }
        Loader {
            id: panelLoader
            ModuleElementStyler{target:panelLoader.item;moduleId:root.designId}
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.panelPad + (islandState.openPanel === "summary" ? root.notchPad/2 : root.notchPad)
            width: Math.max(0,root.panelWidth-2*root.panelPad)
            height: Math.max(0,root.panelHeight-2*root.panelPad)
            asynchronous:true
            active: islandState.expanded && !["barpresets","launcherpresets","setuppresets"].includes(islandState.openPanel)
            sourceComponent: root.panelComponents[islandState.openPanel] ?? controlsPanel
            opacity: islandState.expanded ? entrance.contentOpacity*(root.panelStyle.opacity??100)/100 : 0
            transform: [
                Scale {
                    origin.x: panelLoader.width / 2
                    origin.y: panelLoader.height / 2
                    xScale: entrance.stretchX
                    yScale: entrance.stretchY
                },
                Translate { y: entrance.offset }
            ]

            Behavior on opacity {
                enabled: root.animated && !entrance.fading
                NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
            }
        }
    }

    // Swallows clicks on the panel background so they do not reach the
    // dismiss area covering the rest of the bar. On the control centre's
    // margin the right button arranges it, as it does between its blocks.
    MouseArea {
        anchors.fill: parent
        enabled: islandState.expanded
        acceptedButtons: Qt.AllButtons
        cursorShape: Qt.ArrowCursor
        z: -1
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton && islandState.openPanel === "summary")
                root.open("controls")
            else if (mouse.button === Qt.RightButton && islandState.openPanel === "controls")
                ControlsService.edit(!ControlsService.editing)
        }
    }

    // ── LAYERS ──────────────────────────────────────────────────────────────

    Component {
        id: restLayer
        IslandRest {}
    }

    Component {
        id: summaryLayer
        IslandSummary {collapseProgress:root.hoverCollapseProgress;contentBounceOffset:barBounce.offset;referenceLayout:root.summarising?root.referenceLayout:({})}
    }

    Component {
        id: moduleDetail
        DetailFace {
            moduleId: ModuleService.openId
            onClosed: root.close()
        }
    }

    Component {
        id: notificationLayer
        NotificationLayer {}
    }

    Component {
        id: osdLayer
        OsdLayer {
            icon: islandState.transientIcon
            label: islandState.transientLabel
            progress: islandState.transientProgress
        }
    }

    Component {
        id:documentLibraryPanel
        DocumentLibraryPanel {
            onClosed:root.close()
            onDocumentRequested:path=>{DocumentLibraryService.openDocument(path);root.close()}
            onFullscreenRequested:{root.close();DocumentLibraryService.fullscreenRequested()}
        }
    }
    Component{id:processesPanel;ProcessesPanel{onClosed:root.close()}}

    Component {
        id: controlsPanel
        ControlsPanel {
            onClosed: root.close()
            onPanelRequested: panel => root.open(panel)
            // Settings is a window, not a panel: close the island, then pass
            // the request up.
            onSettingsRequested: {
                root.close()
                root.settingsRequested()
            }
        }
    }

    Component {
        id: appearancePanel
        AppearancePanel {
            page: islandState.openPanel === "palette" ? "palette" : "wallpaper"
            onClosed: root.close()
            // Up and Down switch strips by panel name, so `page` follows
            // `openPanel`.
            onPanelRequested: panel => root.open(panel)
        }
    }

    Component {id:launcherPresetPanel;LauncherPresetPanel {onClosed:root.close()}}
    Component {id:unifiedPresetsPanel;UnifiedPresetsPanel {onClosed:root.close()}}
    Component {
        id: barPresetsPanel
        BarPresetPanel { onClosed: root.close() }
    }

    Component {
        id: launcherPanel
        LauncherPanel {
            onClosed: root.close()
            // `>` lists every panel, so the launcher hands the island over the
            // same way the control centre does.
            onPanelRequested: panel => root.open(panel)
            onSettingsRequested: {
                root.close()
                root.settingsRequested()
            }
        }
    }

    // Wi-Fi and Bluetooth are panels of their own rather than views inside the
    // control centre, because a panel's size is keyed on `openPanel`.
    Component {
        id: networkDetail
        NetworkDetail { onBack: root.open("controls") }
    }

    Component {
        id: soundDetail
        SoundDetail { onBack: root.open("controls") }
    }

    Component {
        id: microphoneDetail
        MicrophoneDetail { onBack: root.open("controls") }
    }

    Component {
        id: brightnessDetail
        BrightnessDetail { onBack: root.open("controls") }
    }

    Component {
        id: nightLightDetail
        NightLightDetail { onBack: root.open("controls") }
    }

    Component {
        id: bluetoothDetail
        BluetoothDetail { onBack: root.open("controls") }
    }

    Component {
        id: trayMenu
        TrayMenuPanel { onClosed: root.close() }
    }

    Component {
        id: statsPanel
        StatsPanel { onClosed: root.close() }
    }

    Component {
        id: overviewPanel
        OverviewPanel { onClosed: root.close() }
    }

    Component {
        id: sessionPanel
        SessionPanel { onClosed: root.close() }
    }

    Component {
        id: authPanel
        AuthPanel {}
    }

    Component {
        id: machinesPanel
        MachinesPanel { onClosed: root.close() }
    }

    Component {
        id: serversPanel
        ServersPanel { onClosed: root.close() }
    }

    Component {
        id: screenTimePanel
        ScreenTimePanel { onClosed: root.close() }
    }

    Component {
        id: cameraPanel
        CameraPanel { onClosed: root.close() }
    }


    Component {
        id: gamesPanel
        GamesPanel { onClosed: root.close() }
    }

    Component {
        id: notesPanel
        NotesPanel { onClosed: root.close() }
    }

    Component {
        id: tasksPanel
        TasksPanel { onClosed: root.close() }
    }

    Component {
        id: keysPanel
        KeysPanel { onClosed: root.close() }
    }

    Component {
        id: packagesPanel
        PackagesPanel { onClosed: root.close() }
    }

    // A module asking for a panel: the arcade's detail opening the arcade.
    Connections {
        target: ModuleService

        function onPanelRequested(panel: string): void {
            root.open(panel)
        }
    }
}
