// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   B A R                                                                  │
// │   the bar · the island and its two sides, in three styles                │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.UPower as Power

import "../theme"
import "../services"
import "SmartAutoHide.js" as SmartHide
import "./widgets"
import "./modules"
import "./island"
import "./island/controls"
import "../components"

// The island in the middle and the two sides (`SettingsService.barZone`), in
// one of three styles:
//
//   grouped   the sides sit against the island and move aside as it grows
//   spread    the sides sit at the screen edges and hold still
//   island    everything in one capsule; the band morphs into whatever the
//             island opens
//
// Every detail opens in the island. The window is full-screen and never
// resizes; the input mask covers the bar and the island, and a focus grab
// closes the island on any click outside it.
//
// ── ONE PER SCREEN, ONE LIVE ────────────────────────────────────────────────
//
// There is one of these on every screen and exactly one of them is `live`:
// the screen being worked on. The live bar opens panels, holds the keyboard
// and shows whatever arrives; the rest are the same bar with the island at
// rest, which is what the other screens were already drawing. So the island
// crossing screens is a flag changing hands — nothing is built, nothing is
// torn down, and what is under the pointer is always the one that answers it.
PanelWindow {
    id: root
    // Let the compositor cover the bar, then prepare it behind the secure
    // surface while the password is being entered, before the exit fade starts.
    visible: SettingsService.arrived && LockMotionService.started
        && (!LockService.locked || !LockService.secure || LockService.awake || LockService.leaving)
    Connections {
        target: LockService
        function onCleaningForLock():void {
            if(chipPopup.visible){LockService.cleanFrameNeeded=true;chipPopup.close(true)}
            if(island.expanded||island.closing||island.state.layer===island.state.layerSummary){
                LockService.cleanFrameNeeded=true
                island.prepareForLock()
                restingScaleMotion.complete();bandPositionMotion.complete();islandCenterMotion.complete();islandTopMotion.complete()
            }
        }
        function onPendingLockChanged(): void { if (LockService.pendingLock) root.dismiss() }
    }
    CornerGuard {}

    // Named for the blur behind it (`windowrules.lua`), which shows only
    // through a ground that is not solid.
    WlrLayershell.namespace: "impasto-bar"
    // A request for root rises over a full-screen window, which covers the
    // top layer; the bar goes back down once it is answered.
    WlrLayershell.layer: island.state.openPanel === "auth" && island.expanded
        ? WlrLayer.Overlay : WlrLayer.Top
    // What is drawn here takes the island's glass (`Theme.surfaceIn`).
    readonly property bool glassy: true
    readonly property color barShadowInk:SettingsService.barShadowUseAccent?Theme.accent:Theme.shadowColor
    readonly property bool powerSaving:Power.PowerProfiles.profile===Power.PowerProfile.PowerSaver
    readonly property bool efficientShadow:SettingsService.powerSaverBarEffects && root.powerSaving && Theme.solid && !root.unified && Math.abs(Theme.notchRoundingPower-2)<.001 && SettingsService.barShadowSharpness===3
    readonly property string groundStyle: Theme.surfaceStyle

    readonly property alias island: island

    // Whether this is the screen being worked on (`shell.qml`). Everything
    // below that touches state the whole shell shares is gated on it, because
    // every screen runs a copy of this file.
    required property bool live

    // Whether this one is drawn at all. The surface is on every screen
    // either way and the reserve is `BarReserve`'s, which never moves, so a
    // desk set to one bar costs no window a re-tile when a hand crosses.
    readonly property bool painted: root.live || SettingsService.barEverywhere

    // The compositor's focus follows the pointer, so by the time anything here
    // is clicked this screen is already the live one. Said outright for the
    // case that is not a journey across the screen: a pointer warped onto the
    // bar, or a compositor not set to follow it.
    signal claimed()

    // Distance from the screen edge to the ends. Matches the compositor's
    // outer gap so the bar lines up with tiled windows.
    readonly property int edgeMargin: SettingsService.barSideMargin

    readonly property string style: SettingsService.barStyle
    readonly property bool spread: root.style === "spread"
    // The bezel is one capsule too, spanning the top edge.
    readonly property bool unified: root.style === "island" || root.style === "bezel"
    // The sides on the wallpaper, without capsules; not in one capsule, whose
    // band is the sides' ground.
    readonly property bool bare: !root.unified && SettingsService.barSides === "bare"
    readonly property bool grouped: !root.spread && !root.unified

    // The bezel: the band is the top of the screen's frame, out to both
    // edges, with the screen's corners curving under its ends. It never
    // moves: what the island shows drops out of its middle.
    readonly property bool edgeToEdge: root.style === "bezel"

    readonly property bool holding: island.expanded||chipPopup.opened

    // Maximum panel width. Spread, the sides stay put, so a panel gets the room
    // between them, unless it is wider than that: then they hide as grouped
    // sides do and it gets the whole bar, like everywhere else. A narrow
    // screen with a full bar would otherwise cut a panel's columns off.
    readonly property int roomBetween: root.width - 2 * (root.edgeMargin
        + Math.max(leftZone.width, rightZone.width) + Theme.capsuleSpacing)
    readonly property bool crowded: root.spread && island.expanded
        && island.panelSize.width > root.roomBetween
    readonly property int panelRoom: root.spread && !root.crowded
        ? root.roomBetween : root.width - 2 * root.edgeMargin

    // Computed rather than read from `island.x`, which comes from an anchor
    // resolved during layout and would lag a frame behind the width.
    // Leave room for the lower curve so the upper shoulder and rim cannot
    // fold backwards over one another at large radii or high powers.
    readonly property real notchShoulder:Math.max(0,Math.min(SettingsService.notchShoulderRadius,island.height-island.radius))
    readonly property real notchShift:SettingsService.notched?Math.max(-Math.max(0,(root.width-island.width)/2-Theme.radiusNotch*2),Math.min(SettingsService.notchOffsetX,Math.max(0,(root.width-island.width)/2-Theme.radiusNotch*2))):0
    readonly property real islandLeft: (root.width - island.width) / 2 + root.notchShift + (SettingsService.islandChipsEnabled && !island.expanded ? IslandChipService.get("clock").offsetX : 0)
    readonly property real islandRight: root.islandLeft + island.width

    // ── ONE CAPSULE ─────────────────────────────────────────────────────────
    //
    // A band a capsule tall, with the sides at its ends and the island in the
    // middle. When the island shows anything beyond the clock, the band morphs
    // into it and the sides are clipped by its closing ends.

    // Inset of each side from the band's edge, clear of the curve.
    // Use the resting body rather than an open module's expanded width.
    // Freeze at the lock request so PAM/privacy activity cannot stretch the lock.
    Binding {
        target: LockStyleService
        property: "barIslandWidth"
        value: root.unified
            ? (root.edgeToEdge ? root.width - 2 * root.edgeMargin
                : ModuleService.restWidth + 2 * root.hostedSlot)
            : ModuleService.restWidth
        when: root.live && !LockService.pendingLock && !LockService.locked
        restoreMode: Binding.RestoreNone
    }

    readonly property int hostedInset: 12

    // The same at both ends, so the clock stays centred on the screen.
    readonly property real hostedSlot: root.unified
        ? root.hostedInset + Math.max(leftZone.width, rightZone.width) + Theme.capsuleSpacing * 2
        : 0

    // The island's width inside the band, animated on the island's clock so
    // the band widens with it. An OSD is wider than the clock and pushes the
    // sides out rather than overlapping them.
    property real restWidth: island.state.layer === island.state.layerOsd
        ? Math.max(ModuleService.restWidth, island.size.width)
        : ModuleService.restWidth

    Behavior on restWidth {
        ConfiguredNumberAnimation { duration: island.morphDuration; curve:island.morphEasing;customCurve:island.morphBezier;spring:island.morphOvershoot }
    }

    // The band at rest: the island's rest width plus a slot for each side.
    readonly property real bodyWidth: {
        if (!root.unified)
            return island.width
        if (root.edgeToEdge)
            return root.width - 2 * root.edgeMargin
        return root.restWidth + 2 * root.hostedSlot
    }

    readonly property real bandRow: Theme.capsuleHeight + island.notchPad

    // The island is showing more than the clock: a panel, a detail, the
    // glance or a notification. An OSD fits in the band and does not count.
    // In zen too, where the sides are away and the band is only the island.
    readonly property bool islandTaken: island.expanded
        || (island.state.layer === island.state.layerSummary&&!island.closingHover)
        || island.state.layer === island.state.layerNotification
        || root.zen
    readonly property real bodyX: root.edgeToEdge
        ? root.edgeMargin : (root.width - root.bodyWidth) / 2

    // 0 at rest, 1 once the island has taken over the band. Animated on the
    // island's clock and curve so the two land together.
    property real bandInto: root.unified && root.islandTaken ? 1 : 0

    Behavior on bandInto {
        enabled: island.animated&&!LockService.preparingFrame
        ConfiguredNumberAnimation {id:bandPositionMotion; duration: island.morphDuration; curve:island.morphEasing;customCurve:island.morphBezier;spring:island.morphOvershoot }
    }

    // Interpolates from the rest width to the island's animated width as
    // `bandInto` goes from 0 to 1. Both run on the same curve, so this is one
    // morph with no clock of its own. The max() stops a spring curve's
    // overshoot from making the band narrower than the island.
    readonly property real bandWidth: root.edgeToEdge
        ? root.width
        : root.bandInto === 0 && !root.islandTaken
            ? root.bodyWidth
            : island.width + (root.bodyWidth - root.restWidth) * Math.max(0, 1 - root.bandInto)
    readonly property real bandX: (root.width - root.bandWidth) / 2

    // Attached (notch mode), only the island reaches the screen edge; the
    // sides stay capsules, centred on `laneY`.
    readonly property int islandTopMargin: Theme.islandTopMargin + (SettingsService.islandChipsEnabled && !island.expanded ? IslandChipService.get("clock").offsetY : 0)

    // How far the glass's light from the top reaches down the notch
    // (`GlassSheen`), for the fillets that carry it on.
    readonly property real notchSheen: Theme.glass && !island.paper ? Theme.glassSheenDepth : 0

    // The line everything on the bar is centred on. Attached, the island
    // reaches the screen edge, so its centre is half a margin higher and the
    // sides move up to match.
    readonly property real laneY: SettingsService.notched
        ? Theme.barTopMargin / 2 : Theme.barTopMargin

    readonly property bool clickHoverEnlarged:SettingsService.barClickHoverEnlarge&&SettingsService.islandSummaryMode==="click"&&root.live&&island.hovered&&!root.islandTaken&&!island.closing&&!root.away&&!LockService.pendingLock&&!LockService.locked&&!LockMotionService.desktopAnimating
    readonly property real clickHoverScale:root.clickHoverScaleX
    property real clickHoverScaleX:root.clickHoverEnlarged?1+SettingsService.barHoverEnlargeAmount/100+SettingsService.barHoverExtraWidth/Math.max(1,island.width):1
    property real clickHoverScaleY:root.clickHoverEnlarged?1+SettingsService.barHoverEnlargeAmount/100+SettingsService.barHoverExtraHeight/Math.max(1,island.height):1
    Behavior on clickHoverScaleX {enabled:!LockService.pendingLock&&!LockService.locked;NumberAnimation {duration:180;easing.type:Easing.OutCubic}}
    Behavior on clickHoverScaleY {enabled:!LockService.pendingLock&&!LockService.locked;NumberAnimation {duration:180;easing.type:Easing.OutCubic}}
    readonly property real visualScaleY:root.baseVisualScale*root.clickHoverScaleY
    readonly property real visualScale:root.baseVisualScale*root.clickHoverScale
    property real baseVisualScale:root.islandTaken?1:Theme.barScale
    Behavior on baseVisualScale {enabled:!LockService.preparingFrame;ConfiguredNumberAnimation {id:restingScaleMotion;duration:island.morphDuration;curve:island.morphEasing;customCurve:island.morphBezier;spring:island.morphOvershoot}}
    readonly property int collapsedHeight: Theme.barBand + IslandChipService.extraBelow

    // Grouped, the sides fade away for every expanded view, including modules.
    // In one capsule they hide whenever the island takes the band, and spread
    // only for a panel too wide to fit between them.
    readonly property bool sidesAway: root.edgeToEdge
        ? root.islandTaken && island.width / 2 > root.width / 2 - root.bodyX - root.hostedSlot
        : root.unified
        ? root.islandTaken
        : root.crowded
            || island.expanded && root.grouped

    anchors {
        top: true
        left: true
        right: true
    }

    // ── SURFACE ─────────────────────────────────────────────────────────────
    //
    // The layer surface is full-screen and never resizes: resizing it on every
    // animation frame makes the bar jitter, because the compositor applies the
    // new size a frame before or after the matching buffer. Input is handled by
    // the mask, which is cheap to change per frame.
    implicitHeight: root.screen.height

    // Input region: the bar's band, plus the island's shape (the band's, in
    // one capsule) with 12 px below it so the bottom edge still counts. The
    // whole screen only while the control centre is being arranged, since
    // blocks are dragged out of the tray card, which moves. Outside clicks are
    // left to the focus grab, so windows under an open panel stay usable.
    readonly property real shapeLeft: root.unified && !root.edgeToEdge
        ? Math.min(root.bandX, root.islandLeft) : root.islandLeft
    readonly property real shapeRight: root.unified && !root.edgeToEdge
        ? Math.max(root.bandX + root.bandWidth, root.islandRight) : root.islandRight
    readonly property bool wholeScreen: root.holding && ControlsService.editing

    // No input at all while desktop widgets are being arranged: dragging one
    // over the bar would move the pointer to this surface, and the desktop
    // would drop the widget. None either where nothing is painted.
    readonly property bool inert: DesktopService.editing || !root.painted || root.away

    // Zen (`barHidden`): the bar waits above the screen and the island comes
    // down only for what it has to show — a panel, a notification, a
    // transient — with the sides left up there.
    readonly property bool zen: SettingsService.barHidden && !SettingsService.barAutoHide
    readonly property bool called: chipPopup.visible||(island.state.layer !== island.state.layerModules
        && island.state.layer !== island.state.layerSummary)
    readonly property var smartArea:{
        const monitor=HyprlandService.monitors.find(m=>m.name===root.screen?.name)
        let width=ModuleService.restWidth
        if(SettingsService.islandChipsEnabled) {
            const gap=SettingsService.islandChipGap||12
            for(const side of ["left","right"])width+=IslandChipService.list(side,SettingsService,false).reduce((sum,e)=>sum+e.config.width+gap+Math.abs(e.config.offsetX||0),0)
        } else width+=root.unified?2*root.hostedSlot:leftZone.width+rightZone.width+2*Theme.capsuleSpacing
        if(root.spread || root.edgeToEdge)width=root.width
        width*=Theme.barScale
        return {x:(monitor?.x||0)+(root.width-width)/2,y:monitor?.y||0,width:width,height:root.collapsedHeight*Theme.barScale}
    }
    readonly property bool smartWindowOverlap:{
        if(!SettingsService.barAutoHideSmart || !SettingsService.barAutoHide)return true
        const monitor=HyprlandService.monitors.find(m=>m.name===root.screen?.name)
        if(!monitor)return false
        const workspace=HyprlandService.activeOn(monitor.name)||monitor.activeWorkspace?.id||0
        return HyprlandService.clients.some(client=>SmartHide.overlaps(client,root.smartArea,workspace,monitor.id))
    }
    property bool autoRevealed:false
    readonly property bool autoHidden:SettingsService.barAutoHide && root.smartWindowOverlap && !root.autoRevealed && !root.called
    readonly property bool away:(root.zen || root.autoHidden) && !root.called
    Timer {id:autoHidePause;interval:SettingsService.autoHideDelay;onTriggered:if(!barHover.hovered)root.autoRevealed=false}

    function screenX(x:real):real{const center=island.x+island.width/2;return root.width/2+(center+(x-center)*root.clickHoverScale-root.width/2)*root.baseVisualScale}
    readonly property real triggerLeft:root.edgeToEdge?0:root.shapeLeft-(SettingsService.notched?root.notchShoulder:0)
    readonly property real triggerRight:root.edgeToEdge?root.width:root.shapeRight+(SettingsService.notched?root.notchShoulder:0)
    readonly property bool edgeTrigger:root.painted&&SettingsService.barAutoHide&&root.autoHidden&&!DesktopService.editing
    onAwayChanged:if(!root.away)CompositorService.refreshRevealedGlass()
    function chipRectOnSurface(rect:rect):rect {
        const depend=[root.clickHoverScaleX,root.clickHoverScaleY,root.baseVisualScale,autoMotion.offset,autoMotion.zoom,root.setupReveal,island.x,island.y,island.width,island.height];
        const a=separateChips.mapToItem(root.contentItem,rect.x,rect.y),b=separateChips.mapToItem(root.contentItem,rect.x+rect.width,rect.y+rect.height);
        return Qt.rect(a.x,a.y,b.x-a.x,b.y-a.y)
    }
    readonly property rect leftChipInput:root.chipRectOnSurface(separateChips.leftBounds)
    readonly property rect rightChipInput:root.chipRectOnSurface(separateChips.rightBounds)
    function closeChipPanel():void {chipPopup.close()}
    function openChipById(id:string):bool {return root.live&&separateChips.activateChip(id)}
    readonly property var chipPanelState:({id:chipPopup.chipId,module:chipPopup.moduleId,side:chipPopup.side,open:chipPopup.opened,progress:chipPopup.progress,source:chipPopup.sourceRect,rect:Qt.rect(chipPopup.x,chipPopup.y,chipPopup.width,chipPopup.height),anchor:chipPopup.placement.edge})
    onLiveChanged:if(!root.live)chipPopup.close(true)
    readonly property var chipAnimationState:({reveal:separateChips.reveal,visible:separateChips.visible,left:separateChips.leftBounds,right:separateChips.rightBounds,clockLeft:separateChips.clockCenter-separateChips.clockWidth/2,clockRight:separateChips.clockCenter+separateChips.clockWidth/2,gap:separateChips.safetyGap})
    mask:Region {
        Region {x:chipPopup.x;y:chipPopup.y;width:!root.inert&&chipPopup.visible?chipPopup.width:0;height:chipPopup.height}
        width:!root.inert&&root.wholeScreen?root.width:0
        height:!root.inert&&root.wholeScreen?root.height:0
        Region {x:root.screenX(root.triggerLeft);width:root.edgeTrigger?(root.triggerRight-root.triggerLeft)*root.visualScale:0;height:SettingsService.autoHideEdge}
        Region {x:root.leftChipInput.x;width:root.edgeTrigger&&SettingsService.islandChipsEnabled?root.leftChipInput.width:0;height:SettingsService.autoHideEdge}
        Region {x:root.rightChipInput.x;width:root.edgeTrigger&&SettingsService.islandChipsEnabled?root.rightChipInput.width:0;height:SettingsService.autoHideEdge}
        Region {x:root.screenX(sides.x+leftZone.x);width:root.edgeTrigger&&!root.sidesAway?leftZone.width*root.visualScale:0;height:SettingsService.autoHideEdge}
        Region {x:root.screenX(sides.x+rightZone.x);width:root.edgeTrigger&&!root.sidesAway?rightZone.width*root.visualScale:0;height:SettingsService.autoHideEdge}
        Region {
            x:root.screenX(root.triggerLeft)
            width:root.inert?0:(root.triggerRight-root.triggerLeft)*root.visualScale
            height:(root.islandTopMargin+island.height+12)*root.visualScaleY
        }
        Region {x:root.screenX(sides.x+leftZone.x);width:!root.inert&&!root.sidesAway?leftZone.width*root.visualScale:0;height:(root.laneY+Theme.capsuleHeight+8)*root.visualScaleY}
        Region {x:root.screenX(sides.x+rightZone.x);width:!root.inert&&!root.sidesAway?rightZone.width*root.visualScale:0;height:(root.laneY+Theme.capsuleHeight+8)*root.visualScaleY}
        Region {x:root.leftChipInput.x;y:root.leftChipInput.y;width:!root.inert&&separateChips.visible?root.leftChipInput.width:0;height:root.leftChipInput.height}
        Region {x:root.rightChipInput.x;y:root.rightChipInput.y;width:!root.inert&&separateChips.visible?root.rightChipInput.width:0;height:root.rightChipInput.height}
    }

    // The reserve is `BarReserve.qml`'s, one strip per screen that outlives
    // every bar, so a window holds still while the island changes screens.
    // Ignoring zones is what keeps the bar against the edge: a surface that
    // reserves nothing is pushed below whatever else reserved.
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    color: "transparent"

    // ── FOCUS ───────────────────────────────────────────────────────────────
    //
    // On-demand keyboard focus plus a Hyprland focus grab while the island is
    // open. The grab keeps the keyboard here when the pointer crosses a window
    // (with `follow_mouse`, on-demand focus alone loses it), and a click on any
    // other surface clears it, which closes the island. The compositor
    // restores focus when the grab ends. Both stand down while the capture
    // surface is up, so an open panel waits under it instead of closing, and
    // while the session is locked, where a grab would keep the keyboard from
    // the other screens' lock.
    readonly property bool holdsKeyboard: root.live && (island.expanded||chipPopup.opened)
        && !CaptureService.active && !LockService.pendingLock && !LockService.locked

    WlrLayershell.keyboardFocus: root.holdsKeyboard
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        active: root.holdsKeyboard
        windows: [root]
        onCleared: root.dismiss()
    }

    HoverHandler {
        id:barHover
        onHoveredChanged:{
            if(hovered){root.claimed();root.autoRevealed=true;autoHidePause.stop()}
            else autoHidePause.restart()
        }
    }

    // ── OPENING A DETAIL ────────────────────────────────────────────────────
    //
    // Every activation on the bar comes through here
    // (`ModuleService.activate`). Clicking the open module again closes it; any
    // other replaces it.
    function activate(id: string): void {
        chipPopup.close(true)
        if (ModuleService.openId === id) {
            root.dismiss()
            return
        }

        // Always in the island, whatever the style or screen.
        ModuleService.openHost = "island"
        ModuleService.openId = id
        island.open("module")
    }

    function dismiss(): void {
        chipPopup.close()
        if (island.expanded)
            island.close()
        if(!island.closing)ModuleService.close()
    }

    // Every bar hears these; only the live one answers, since the panel opens
    // in its island.
    Connections {
        target: ModuleService
        enabled: root.live

        function onActivationRequested(id: string): void {
            root.activate(id)
        }

        // Bar buttons for panels (launcher, overview) toggle them.
        function onPanelToggled(panel: string): void {
            chipPopup.close(true)
            island.toggle(panel)
        }

        // The service closed the detail, e.g. the player went away.
        function onOpenIdChanged(): void {
            if (ModuleService.openId === "" && island.state.openPanel === "module")
                island.close()
        }
    }

    // Lets a bar button stay lit while its panel is open. One writer: the
    // live bar, since two bars binding the same property is a conflict.
    Binding {
        target: ModuleService
        property: "shownPanel"
        value: island.state.openPanel
        when: root.live
    }

    Connections {
        target: island.state

        // The island left the detail (Escape, a click outside, another panel).
        function onOpenPanelChanged(): void {
            if(island.state.openPanel!=="")chipPopup.close(true)
            if (island.state.openPanel !== "module" && ModuleService.openHost === "island")
                ModuleService.close()
        }
    }

    // Clicks on the bar outside the open island close it. The bar is inside
    // the focus grab, so the grab never sees them.
    MouseArea {
        anchors.fill: parent
        enabled: root.holding
        onClicked: root.dismiss()
    }

    AutoHideMotion {
        id:autoMotion
        hidden:root.away
        animated:!SettingsService.gameMode && Theme.motion>0 && !LockService.pendingLock && !LockService.locked
        style:SettingsService.barAutoHide||!root.zen?SettingsService.autoHideAnimation:"slide"
        showDuration:SettingsService.barAutoHide||!root.zen?SettingsService.autoHideShowDuration:Theme.durationMedium
        hideDuration:SettingsService.barAutoHide||!root.zen?SettingsService.autoHideHideDuration:Theme.durationMedium
        distance:(root.collapsedHeight+Theme.barTopMargin)*root.visualScale+SettingsService.autoHideTravel
    }
    readonly property real setupReveal:SetupPresetService.phase
    readonly property real setupShift:SettingsService.setupTransitionStyle==="slide"||SettingsService.setupTransitionStyle==="bounce"?SettingsService.setupTransitionDistance:0

    ChipModulePopup {
        id:chipPopup
        z:20
        viewport:Qt.size(root.width,root.height)
        barConfiguration:IslandPresetService.presentation
        sourceRect:root.chipRectOnSurface(separateChips.chipRect(chipPopup.chipId||"internet"))
    }

    // ── THE FACE ────────────────────────────────────────────────────────────
    //
    // Everything this bar draws. The surface stays on every screen whatever
    // `barEverywhere` says, so the reserve never moves and no window is ever
    // re-tiled by a hand crossing; what the setting decides is only whether
    // this is painted. Nothing is built or torn down either way.
    Item {
        id: face

        width: parent.width
        height: parent.height
        y:autoMotion.offset-(1-root.setupReveal)*root.setupShift
        scale:autoMotion.zoom*root.baseVisualScale
        transform:Scale {origin.x:island.x+island.width/2;origin.y:island.y+island.height/2;xScale:root.clickHoverScaleX;yScale:root.clickHoverScaleY}
        transformOrigin:Item.Top
        visible: root.painted || face.opacity > 0
        opacity:(root.painted?1:0)*Math.max(0,Math.min(1,root.setupReveal))*autoMotion.alpha

        Behavior on opacity {
            enabled:!SetupPresetService.transitioning && !SettingsService.barAutoHide && !autoMotion.running
            NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }


        // ── SHADOW ──────────────────────────────────────────────────────────────
        //
        // The window shadow's numbers, on its own setting (`barShadow`). The
        // band, the island and the notch fillets touch, so they share one
        // flattened layer; separate shadows would draw a seam where they
        // overlap. The side capsules cast their own (`BarZone`).
        //
        // Cast from a copy of the shapes: layering the real bar would re-blur the
        // full-screen surface every time the clock or the spectrum repaints.
        //
        // The copy is grown by `Theme.shadowBarSpread` and blurred. MultiEffect's
        // `shadowEnabled` would also draw the source, showing the enlarged copy as
        // a black rim. `layer.effect` rather than a hidden `source` item, which
        // does not work inside a Repeater.
        // Keep blur textures around the silhouette, rather than allocating
        // multiple full-screen buffers every frame of a module resize.
        readonly property real shadowBudgetWidth:island.settled?island.width:island.morphWidthBudget
        readonly property real shadowBudgetHeight:island.settled?island.height:island.morphHeightBudget
        readonly property real shadowBudgetLeft:root.islandLeft-(face.shadowBudgetWidth-island.width)/2
        readonly property real shadowPadding:Theme.shadowBarRange*2+Theme.shadowBarSpread+4+Math.max(Math.abs(SettingsService.barShadowOffsetX),Math.abs(SettingsService.barShadowOffsetY))
        readonly property real shadowLeft:root.edgeToEdge?0:Math.floor(Math.max(0,Math.min(face.shadowBudgetLeft-root.notchShoulder*3,root.unified?root.bandX:face.shadowBudgetLeft)-face.shadowPadding)/64)*64
        readonly property real shadowRight:root.edgeToEdge?root.width:Math.min(root.width,Math.ceil((Math.max(face.shadowBudgetLeft+face.shadowBudgetWidth+root.notchShoulder*3,root.unified?root.bandX+root.bandWidth:face.shadowBudgetLeft+face.shadowBudgetWidth)+face.shadowPadding)/64)*64)
        readonly property real shadowBottom:Math.min(root.height,Math.ceil((Math.max(island.y+face.shadowBudgetHeight,root.unified?band.y+Math.max(band.height,face.shadowBudgetHeight):0)+face.shadowPadding)/64)*64)
        Loader {
            id:shadowCache
            x:face.shadowLeft+SettingsService.barShadowOffsetX;y:SettingsService.barShadowOffsetY
            width:Math.max(1,face.shadowRight-face.shadowLeft)
            height:Math.max(1,face.shadowBottom)
            active: Theme.barShadowShown && !root.efficientShadow
            sourceComponent: shadowBody
        }

        Loader {
            active:Theme.barShadowShown && root.efficientShadow
            sourceComponent:RectangularShadow {
                x:root.islandLeft+SettingsService.barShadowOffsetX
                y:island.y-(SettingsService.notched?Theme.shadowBarRange:0)+SettingsService.barShadowOffsetY
                width:island.width
                height:island.height+(SettingsService.notched?Theme.shadowBarRange:0)
                radius:island.radius
                topLeftRadius:SettingsService.notched?0:island.topLeftRadius
                topRightRadius:SettingsService.notched?0:island.topRightRadius
                bottomLeftRadius:island.bottomLeftRadius
                bottomRightRadius:island.bottomRightRadius
                blur:Theme.shadowBarRange
                spread:Theme.shadowBarSpread
                color:Qt.rgba(root.barShadowInk.r,root.barShadowInk.g,root.barShadowInk.b,Math.min(1,Theme.barShadowOpacity*Theme.barShadowBoost))
                cached:false
            }
        }

        Component {
            id: shadowBody

            // Under a ground that lets the screen through, the shapes are cut
            // out of their shadow, so it falls outside them and does not show
            // through.
            Item {
                layer.enabled: !Theme.solid || Theme.barShadowBoost>1 || SettingsService.barShadowSharpness!==3 || SettingsService.barShadowUseAccent
                layer.effect:BlackShadowDensity {
                    shadowInk:root.barShadowInk
                    falloffPower:SettingsService.barShadowSharpness/3
                    gain:Theme.barShadowBoost
                    maskEnabled:Theme.solid?0:1
                    cutout:cutoutShape
                }

                Item {
                    id: cutoutShape

                    anchors.fill: parent
                    visible: false
                    layer.enabled: !Theme.solid

                    Item {
                        x:-SettingsService.barShadowOffsetX;y:-SettingsService.barShadowOffsetY
                        width:parent.width;height:parent.height
                    PowerRectangle {
                        roundingPower:island.roundingPower
                        x: band.x-face.shadowLeft
                        y: SettingsService.notched ? 0 : band.y
                        width: band.width
                        height: band.y + band.height - y
                        radius: band.radius
                        topLeftRadius: band.topLeftRadius
                        topRightRadius: band.topRightRadius
                        // Not `visible`: inside the hidden source it reads false
                        // and the band is left out of the mask.
                        opacity: root.unified && !root.edgeToEdge ? 1 : 0
                    }

                    // Attached, the shadow runs up to the screen's edge, so the
                    // cut does too while the island slides up into the notch.
                    PowerRectangle {
                        roundingPower:island.roundingPower
                        x: root.islandLeft-face.shadowLeft
                        y: SettingsService.notched ? 0 : island.y
                        width: island.width
                        height: island.y + island.height - y
                        radius: island.radius
                        topLeftRadius: SettingsService.notched ? 0 : island.topLeftRadius
                        topRightRadius: SettingsService.notched ? 0 : island.topRightRadius
                        opacity: root.edgeToEdge ? 0 : 1
                    }

                    // The bezel cuts its whole silhouette out, corners and drop.
                    Loader {
                        active:root.edgeToEdge
                        sourceComponent:BezelShape {
                        width: root.width
                        height: root.height
                        opacity: root.edgeToEdge ? 1 : 0
                        bandHeight: band.height
                        corner: bezelEdge.corner
                        dropLeft: drop.x
                        dropRight: drop.x + drop.width
                        dropDepth: drop.visible ? drop.depth : 0
                        dropRadius: island.radius
                        color: "black"
                    }
                    }

                    Repeater {
                        model: [notchLeft, notchRight]

                        NotchFillet {
                            required property var modelData

                            x: modelData.x-face.shadowLeft
                            y: modelData.y
                            width: modelData.width
                            height: modelData.height
                            opacity: modelData.visible && !root.edgeToEdge ? 1 : 0
                            mirrored: modelData.mirrored
                            color: "black"
                        }
                    }
                    }
                }

                Item {
                    id: caster
                    // A soft shadow needs no full-resolution source texture.
                    // Its logical size and all user blur/range values stay intact.
                    layer.textureSize:Qt.size(Math.max(1,Math.ceil(width*(root.powerSaving?.25:.5))),Math.max(1,Math.ceil(height*(root.powerSaving?.25:.5))))
                    layer.smooth:true

                    // Attached, the layer runs above the screen by the blur's reach and
                    // the shapes run up into it, so the blur reads the notch as going on
                    // past the edge and the shadow keeps its weight up to the top.
                    anchors.fill: parent
                    anchors.topMargin: -caster.pad
                    opacity: Theme.barShadowOpacity

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 1
                        blurMax: Math.min(64,Math.max(2,Theme.shadowBarRange-Theme.shadowBarSpread))
                    blurMultiplier: Math.max(1,(Theme.shadowBarRange-Theme.shadowBarSpread)/64)
                    }

                    readonly property int spread: Theme.shadowBarSpread
                    readonly property int pad: SettingsService.notched ? Theme.shadowBarRange : 0

                    PowerRectangle {
                        roundingPower:island.roundingPower
                        x: band.x-face.shadowLeft - caster.spread
                        y: band.y - caster.spread
                        width: band.width + 2 * caster.spread
                        height: band.height + 2 * caster.spread + caster.pad
                        radius: band.radius + caster.spread
                        topLeftRadius: band.topLeftRadius > 0 ? band.topLeftRadius + caster.spread : 0
                        topRightRadius: band.topRightRadius > 0 ? band.topRightRadius + caster.spread : 0
                        visible: body.visible && !root.edgeToEdge
                        color: Theme.shadowColor
                    }

                    PowerRectangle {
                        roundingPower:island.roundingPower
                        x: root.islandLeft-face.shadowLeft - caster.spread
                        y: island.y - caster.spread
                        width: island.width + 2 * caster.spread
                        height: island.height + 2 * caster.spread + caster.pad
                        radius: island.radius + caster.spread
                        topLeftRadius: island.topLeftRadius > 0 ? island.topLeftRadius + caster.spread : 0
                        topRightRadius: island.topRightRadius > 0 ? island.topRightRadius + caster.spread : 0
                        visible: !root.edgeToEdge
                        color: Theme.shadowColor
                    }

                    // The bezel casts from its whole silhouette, moved down by
                    // the spread: its top and sides are the screen's edges.
                    Loader {
                        active:root.edgeToEdge
                        sourceComponent:BezelShape {
                        y: caster.pad + caster.spread
                        width: root.width
                        height: root.height
                        visible: root.edgeToEdge && body.visible
                        bandHeight: band.height
                        corner: bezelEdge.corner
                        dropLeft: drop.x
                        dropRight: drop.x + drop.width
                        dropDepth: drop.visible ? drop.depth : 0
                        dropRadius: island.radius
                        color: Theme.shadowColor
                    }
                    }

                    // The fillets grown by the spread as the rectangles are: the same
                    // centre, a radius short by the spread, and a strip for the top
                    // edge moved up by it. Past the tip the strip runs on along the
                    // edge and fades out, or the shadow down the curve stops square
                    // where the curve meets the edge.
                    Repeater {
                        model: [notchLeft, notchRight]

                        Item {
                            required property var modelData

                            x: modelData.x-face.shadowLeft
                            y: caster.pad + modelData.y
                            width: modelData.width
                            height: modelData.height
                            visible: modelData.visible && !root.edgeToEdge
                            opacity: modelData.opacity

                            // Solid only: along the edge of the screen a
                            // see-through notch would show it as a stain.
                            Rectangle {
                                y: -caster.pad
                                visible: Theme.solid
                                width: parent.width
                                height: caster.pad + caster.spread
                                color: Theme.shadowColor
                            }

                            Rectangle {
                                id: tail

                                readonly property bool mirrored: parent.modelData.mirrored

                                x: mirrored ? -width : parent.width
                                y: -caster.pad
                                visible: Theme.solid
                                width: parent.width * 2
                                height: caster.pad + caster.spread
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: tail.mirrored ? "transparent" : Theme.shadowColor }
                                    GradientStop { position: 1; color: tail.mirrored ? Theme.shadowColor : "transparent" }
                                }
                            }

                            NotchFillet {
                                x: parent.modelData.mirrored ? 0 : caster.spread
                                y: caster.spread
                                width: Math.max(0, parent.width - caster.spread)
                                height: Math.max(0, parent.height - caster.spread)
                                mirrored: parent.modelData.mirrored
                                color: Theme.shadowColor
                            }
                        }
                    }

                }
            }
        }

        // ── BAND ────────────────────────────────────────────────────────────────
        //
        // Two shapes of the same black: the band, and the island on top of it.
        // Neither has an outline, which would draw the seam between them.
        Item {
            id: body

            anchors.fill: parent
            visible: root.unified

            // Grows with the island; at rest both share height and radius.
            PowerRectangle {
                        roundingPower:island.roundingPower
                id: band

                x: root.bandX
                y: root.islandTopMargin
                width: root.bandWidth
                height: root.edgeToEdge ? root.bandRow : Math.max(root.bandRow, island.height)
                radius: island.radius
                topLeftRadius: SettingsService.notched ? 0 : band.radius
                topRightRadius: SettingsService.notched ? 0 : band.radius
                // Edge to edge, the screen's corners round it off below, so
                // its own ends come in square and round as it draws in.
                bottomLeftRadius: root.edgeToEdge ? 0 : band.radius
                bottomRightRadius: root.edgeToEdge ? 0 : band.radius
                color: island.surfaceColor

                // The band is the ground here, so it carries the glass.
                GlassSheen {
                    shape: band
                    visible: Theme.glass && !island.paper
                    edges: !SettingsService.notched
                }

                // Clicking the band opens the island. The sides sit above it and
                // take their own clicks.
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: island.open("controls")
                }
            }

            // The screen's top corners, under the band's ends, when the screen
            // is rounded.
            Repeater {
                model: root.edgeToEdge && SettingsService.screenCorners ? [0, 90] : []

                ScreenCorner {
                    required property int modelData

                    x: modelData === 0 ? band.x : band.x + band.width - width
                    y: band.y + band.height
                    turn: modelData
                    color: island.surfaceColor
                }
            }

            // Edge to edge, the part of the island below the band, in the
            // band's ground, and the two fillets joining it to the band.
            // Starts under the band, not behind it, so a see-through ground is
            // not laid twice. Its curves, and the fillets', never run deeper
            // than the drop itself: a few pixels out of the band is a few
            // pixels of flat edge, not two bumps.
            Rectangle {
                id: drop

                readonly property real depth: island.y + island.height - (band.y + band.height)

                visible: root.edgeToEdge && drop.depth > 0
                x: root.islandLeft
                y: band.y + band.height
                width: island.width
                height: drop.depth
                radius: Math.min(island.radius, drop.depth)
                topLeftRadius: 0
                topRightRadius: 0
                color: band.color
            }

            Repeater {
                model: drop.visible ? [true, false] : []

                NotchFillet {
                    required property bool modelData

                    width: Math.min(Theme.radiusNotch * 2, drop.depth)
                    height: width
                    x: modelData ? drop.x - width : drop.x + drop.width
                    y: drop.y
                    mirrored: modelData
                    color: band.color
                }
            }
        }

        IndividualIslandChips {
            id: separateChips
            transform:Scale {origin.x:island.x+island.width/2;origin.y:island.y+island.height/2;xScale:SettingsService.barHoverEnlargeBackgroundOnly?1/root.clickHoverScaleX:1;yScale:SettingsService.barHoverEnlargeBackgroundOnly?1/root.clickHoverScaleY:1}
            ModuleElementStyler{target:separateChips;moduleId:"bar"}
            anchors.fill: parent
            clockCenter:island.x+island.width/2
            clockWidth:Math.max(ModuleService.restWidth,island.width)*(SettingsService.barHoverEnlargeBackgroundOnly?root.clickHoverScaleX:1)
            clockY:island.y
            clockHeight:Theme.capsuleHeight
            shoulderClearance:SettingsService.notched?root.notchShoulder*(SettingsService.barHoverEnlargeBackgroundOnly?root.clickHoverScaleX:1):0
            expandedChipId:chipPopup.visible?chipPopup.chipId:""
            onChipActivated:(id,side,configuration)=>{root.claimed();island.close();chipPopup.openChip(id,side,configuration)}
            showing:(SettingsService.chipFollowModules?!root.zen:!root.islandTaken&&island.width<=Math.max(ModuleService.restWidth*1.35,ModuleService.restWidth+48))&&(!root.away||SettingsService.barAutoHide)
            externalOpacity:LockMotionService.desktopAnimating?LockMotionService.alpha:1
        }

        DynamicIsland {
            id: island
            externalHovered:barHover.hovered&&!chipPopup.visible
            summaryAllowed:!chipPopup.visible
            hoverContentScaleX:SettingsService.barHoverEnlargeBackgroundOnly?1/root.clickHoverScaleX:1
            hoverContentScaleY:SettingsService.barHoverEnlargeBackgroundOnly?1/root.clickHoverScaleY:1

            active: root.live
            hosted: root.unified
            // Leave actual room for both chip strips, including on scaled bars.
            roomForPanel:SettingsService.islandChipsEnabled&&SettingsService.chipFollowModules
                ?Math.min(root.panelRoom,Math.max(160,root.width/root.visualScale-2*root.edgeMargin-2*Math.max(separateChips.leftBounds.width?separateChips.leftBounds.width+separateChips.safetyGap:0,separateChips.rightBounds.width?separateChips.rightBounds.width+separateChips.safetyGap:0)-2*Math.abs(root.notchShift)))
                :root.panelRoom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: root.notchShift+(SettingsService.islandChipsEnabled && !island.expanded ? IslandChipService.get("clock").offsetX : 0)
            anchors.top: parent.top
            anchors.topMargin: root.islandTopMargin
            // Edge to edge, out of the band only as far as it drops.
            bottomLeftRadius: root.edgeToEdge ? Math.max(0, Math.min(island.radius, drop.depth)) : island.radius
            bottomRightRadius: root.edgeToEdge ? Math.max(0, Math.min(island.radius, drop.depth)) : island.radius

            Behavior on anchors.horizontalCenterOffset {
                enabled:island.animated&&!LockService.preparingFrame
                NumberAnimation {id:islandCenterMotion;duration:Theme.durationMorph;easing.type:Easing.OutCubic}
            }
            Behavior on anchors.topMargin {
                enabled: island.animated&&!LockService.preparingFrame
                NumberAnimation {id:islandTopMotion; duration: Theme.durationMedium; easing.type: Theme.easing }
            }
        }

        // The island's hairline, drawn round the band once it takes the island's
        // shape. Above both, since the opaque island covers the band's own edge.
        // None at rest and none in paper mode.
        PowerRectangle {
                        roundingPower:island.roundingPower
            id: outline

            x: band.x
            y: band.y
            width: band.width
            height: band.height
            radius: band.radius
            topLeftRadius: band.topLeftRadius
            topRightRadius: band.topRightRadius
            visible: root.unified && !island.paper && !SettingsService.notched
            color: "transparent"
            border.width: 1
            border.color: root.islandTaken ? Theme.islandRim : "transparent"

            Behavior on border.color { ColorAnimation { duration: Theme.durationMedium } }
        }

        // The control centre's tray card while its grid is being arranged. On this
        // surface so blocks can be dragged from it onto the island; it fills the
        // surface and starts under the island.
        Item {
            id: overlay

            anchors.fill: parent
            z: 3

            // Beside the island when the screen has room on both sides for
            // the card's widest block: two cards of one size on the left, the
            // grid's size over the top row, and the card of blocks on the
            // right, each side as tall as the island at its largest, whatever
            // size it is now. Measured
            // against the panel's declared size, not the island's, which is
            // still opening. Otherwise the size and the blocks stack under it.
            readonly property real side: (overlay.width - ControlsService.panelWidth) / 2
                - 2 * Theme.desktopGutter
            readonly property bool aside: blocks.item !== null && overlay.side >= blocks.item.narrowest
            readonly property real tall: ControlsService.tallestPanel
            readonly property real cardWidth: blocks.item ? blocks.item.card.width : 0
            // The cards' top: the island's, but never flush with the screen
            // edge when the island is attached, which the card of blocks
            // cannot be either.
            readonly property real cardsTop: Math.max(root.islandTopMargin, Theme.desktopGutter)
            // Half the island each, unless the top row's editor needs more.
            readonly property real half: Math.max((overlay.tall - Theme.desktopGutter) / 2,
                sideCards.item ? sideCards.item.need : 0)

            // Under the island, when there is no room beside it.
            Loader {
                id: arranging

                x: (parent.width - width) / 2
                y: root.islandTopMargin + island.height + Theme.desktopGutter
                active: root.live && ControlsService.editing && !overlay.aside
                sourceComponent: GridSize {}
            }

            Loader {
                id: sideCards

                x: (overlay.width - ControlsService.panelWidth) / 2
                    - Theme.desktopGutter - overlay.cardWidth
                y: overlay.cardsTop
                active: root.live && ControlsService.editing && overlay.aside
                sourceComponent: Column {
                    readonly property real need: topRow.implicitHeight + 2 * Theme.panelPadding

                    spacing: Theme.desktopGutter

                    // The figure over the miniature, filling the card.
                    Rectangle {
                        width: overlay.cardWidth
                        height: overlay.half
                        radius: Theme.radiusLarge
                        color: Theme.island
                        border.color: Theme.borderIn(QsWindow.window)
                        border.width: 1

                        GridSize {
                            anchors.fill: parent
                            anchors.margins: Theme.panelPadding
                            bare: true
                            filling: true
                        }
                    }

                    // The top row's buttons, arranged as on the settings page.
                    PowerRectangle {
                        roundingPower:island.roundingPower
                        width: overlay.cardWidth
                        height: overlay.half
                        radius: Theme.radiusLarge
                        color: Theme.island
                        border.color: Theme.borderIn(QsWindow.window)
                        border.width: 1

                        TopRowEditor {
                            id: topRow

                            x: Theme.panelPadding
                            y: Theme.panelPadding
                            width: parent.width - 2 * Theme.panelPadding
                            fillTo: parent.height - 2 * Theme.panelPadding
                        }
                    }
                }
            }

            Loader {
                id: blocks

                anchors.fill: parent
                active: root.live && ControlsService.editing
                sourceComponent: ControlsTray {
                    host: overlay
                    homeLeft: overlay.aside
                        ? (overlay.width + ControlsService.panelWidth) / 2 + Theme.desktopGutter : -1
                    room: overlay.side
                    tall: 2 * overlay.half + Theme.desktopGutter
                    homeTop: overlay.aside ? overlay.cardsTop
                        : arranging.y + arranging.height + Theme.desktopGutter
                }
            }
        }

        // Notch fillets flaring from the island's edges out to the screen edge.
        // In one capsule they follow whichever edge is further out, the band's or
        // the island's, since a spring curve can push the island past the band.
        NotchFillet {
            id: notchLeft
            joinOverlap:color.a>=.999?1.5:0
            width:root.notchShoulder+joinOverlap;height:root.notchShoulder

            x: (root.unified ? Math.min(root.bandX, root.islandLeft) : root.islandLeft) - width + joinOverlap
            anchors.top: parent.top
            visible: SettingsService.notched
            mirrored: true
            color: island.surfaceColor
            sheenReach: root.notchSheen
        }

        NotchFillet {
            id: notchRight
            joinOverlap:color.a>=.999?1.5:0
            width:root.notchShoulder+joinOverlap;height:root.notchShoulder

            x: (root.unified ? Math.max(root.bandX + root.bandWidth, root.islandRight) : root.islandRight) - joinOverlap
            anchors.top: parent.top
            visible: SettingsService.notched
            color: island.surfaceColor
            sheenReach: root.notchSheen
        }

        // On glass, attached, the island and its fillets are one pane: the
        // light from the top runs on into the fillets, and the thick edge
        // follows the outline below rather than the island's own rectangle.
        // Its light falls as the sheen's does, from one side on liquid, over
        // the whole pane fillets and all.
        LitEdge {
            id: notchEdge

            readonly property real fillet:root.notchShoulder
            readonly property real shapeHeight: root.unified ? band.height : island.height

            x: root.shapeLeft - notchEdge.fillet
            width: root.shapeRight - root.shapeLeft + 2 * notchEdge.fillet
            height: notchEdge.shapeHeight
            // Edge to edge, the band is the bezel's own edge and the island
            // drops out of it with no outline to trace.
            visible: SettingsService.notched && !Theme.solid && !island.paper && !root.edgeToEdge

            Repeater {
                model: Theme.glass ? [[1, 1], [2, 0.6], [3, 0.35], [4, 0.15]] : []

                NotchOutline {
                    fillet:notchEdge.fillet
                    required property var modelData

                    inset: modelData[0]
                    shapeLeft: notchEdge.fillet
                    shapeRight: notchEdge.width - notchEdge.fillet
                    shapeHeight: notchEdge.shapeHeight
                    radius: island.radius
                    color: Qt.rgba(1, 1, 1, Theme.edgeOf(Theme.surfaceStyle) * modelData[1])
                }
            }

            // Attached, the hairline runs down the fillets and round the shape,
            // and not along the screen edge. In one capsule only while the
            // island has the band, as `outline` above. Lit from one side, the
            // rim's light is drawn here so it fades with the edge.
            NotchOutline {
                fillet:notchEdge.fillet
                shapeLeft: notchEdge.fillet
                shapeRight: notchEdge.width - notchEdge.fillet
                shapeHeight: notchEdge.shapeHeight
                radius: island.radius
                color: !root.unified || root.islandTaken
                    ? (notchEdge.lit ? Qt.rgba(1, 1, 1, Theme.litRim) : Theme.islandRim)
                    : "transparent"

                Behavior on color { ColorAnimation { duration: Theme.durationMedium } }
            }
        }

        // The bezel's edge, on glass: one rim and thick edge round the band's
        // underside, the screen's corners and whatever drops out of it, lit
        // as one pane — from one side on liquid, which falls on its two ends.
        LitEdge {
            id: bezelEdge

            readonly property real corner: SettingsService.screenCorners ? Theme.screenRadius : 0

            width: root.width
            height: band.height + Math.max(bezelEdge.corner, drop.visible ? drop.depth : 0)
            visible: root.edgeToEdge && Theme.glass && !island.paper

            Repeater {
                model: root.edgeToEdge && Theme.glass && !island.paper ? [[0, 1], [1, 1], [2, 0.6], [3, 0.35], [4, 0.15]] : []

                BezelOutline {
                    required property var modelData

                    inset: modelData[0]
                    bandHeight: band.height
                    corner: bezelEdge.corner
                    dropLeft: drop.x
                    dropRight: drop.x + drop.width
                    dropDepth: drop.visible ? drop.depth : 0
                    dropRadius: island.radius
                    color: modelData[0] === 0
                        ? (bezelEdge.lit ? Qt.rgba(1, 1, 1, Theme.litRim) : Theme.islandRim)
                        : Qt.rgba(1, 1, 1, Theme.edgeOf(Theme.surfaceStyle) * modelData[1])
                }
            }
        }

        component BareShadow: MultiEffect {
            shadowEnabled: Theme.barShadowShown
            shadowOpacity:Math.max(0,Math.min(2,SettingsService.barShadowIntensity/100))
            blurMax: Math.min(64,Math.max(2,Theme.barShadowReach))
            blurMultiplier: Math.max(1,Theme.barShadowReach/64)
            shadowBlur: 1
            shadowVerticalOffset: 1
            shadowColor: Theme.barShadow
        }

        // ── SIDES ───────────────────────────────────────────────────────────────
        //
        // Grouped, the sides are anchored to the island's animated edges, so they
        // move aside on its clock with nothing else to animate. Spread, they stay
        // in the corners. In one capsule they are the band's ends; while it morphs
        // they are clipped by it and fade out faster than it closes.
        Item {
            id: sides

            readonly property bool cropped: root.unified && root.bandInto > 0

            x: sides.cropped ? band.x : 0
            y: 0
            width: sides.cropped ? band.width : root.width
            height: root.height
            clip: sides.cropped
            opacity: root.zen ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
            }

            // On the wallpaper, the sides are cast twice: the shadow's own
            // shadow is what makes a thin dark edge dense enough to hold white
            // off a light picture, which one blurred copy of a small glyph is
            // not.
            layer.enabled: root.bare
            layer.effect: BareShadow {}

            BarZone {
                id: leftZone

                entries: SettingsService.barItems("left")
                chromeless: root.unified || root.bare
                overWallpaper: root.bare

                layer.enabled: root.bare
                layer.effect: BareShadow {}
                x: (root.unified ? root.bodyX + root.hostedInset
                    : root.spread ? root.edgeMargin
                    : root.islandLeft - Theme.capsuleSpacing - leftZone.width) - sides.x
                y: root.laneY
                opacity: root.sidesAway ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.unified && root.sidesAway ? Theme.durationFast : Theme.durationMedium
                        easing.type: Theme.easing
                    }
                }
            }

            BarZone {
                id: rightZone

                entries: SettingsService.barItems("right")
                chromeless: root.unified || root.bare
                overWallpaper: root.bare

                layer.enabled: root.bare
                layer.effect: BareShadow {}
                x: (root.unified ? root.bodyX + root.bodyWidth - root.hostedInset - rightZone.width
                    : root.spread ? root.width - root.edgeMargin - rightZone.width
                    : root.islandRight + Theme.capsuleSpacing) - sides.x
                y: root.laneY
                opacity: root.sidesAway ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.unified && root.sidesAway ? Theme.durationFast : Theme.durationMedium
                        easing.type: Theme.easing
                    }
                }
            }
        }
    }
}
