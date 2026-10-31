import QtQuick
import "../theme"
import "../services"
import "../components"
import "../bar/island"
import "../bar/widgets"
import "common"

// All motion is inside the secure lock; it never postpones locking.
Item {
    id: root
    property real held: 1
    property bool capturedBar: false
    property bool preview: false
    property bool previewLeaving: false
    readonly property bool leaving: root.preview ? root.previewLeaving : LockService.leaving&&!LockService.unlockToDesktop
    property real timeline: 0
    property real morph:0
    readonly property real phase:Math.max(0,Math.min(1,root.morph))
    readonly property bool desktopEntry:!root.preview&&root.leaving&&LockMotionService.sessionUnlock
    readonly property real activeProgress:root.desktopEntry?LockMotionService.progress:root.leaving?root.phase:1-root.phase
    readonly property real activeOpacity:root.desktopEntry?LockMotionService.alpha:root.leaving?Math.max(0,Math.min(1,(root.phase-.35)/.65)):Math.max(0,Math.min(1,1-root.phase/.42))
    readonly property real symbolOpacity:root.desktopEntry?LockMotionService.symbolAlpha:root.leaving?Math.max(0,Math.min(1,1-root.phase/.35)):Math.max(0,Math.min(1,(root.phase-.42)/.58))
    readonly property string morphStyle:SettingsService.lockIslandTransition
    readonly property real contentScale:root.desktopEntry?LockMotionService.contentScale:root.morphStyle==="bounce"?.84+.16*root.activeProgress:root.morphStyle==="smooth"?.96+.04*root.activeProgress:1
    readonly property real contentOffset:root.desktopEntry?LockMotionService.contentOffset:root.morphStyle==="bounce"?8*(1-root.activeProgress):root.morphStyle==="smooth"?4*(1-root.activeProgress):0
    readonly property color activeSurface:{
        if(Theme.solid&&SettingsService.islandChipsEnabled){
            const surface=IslandChipService.get("clock").surface
            if(surface==="outline")return "transparent"
            if(surface==="glass")return Qt.rgba(1,1,1,.14)
            if(surface==="solid")return "#080a0c"
        }
        if(!Theme.solid || SettingsService.notched)return Theme.islandGround
        return SettingsService.floatingBarSurface==="black"?"#000000":Theme.islandSurface
    }
    function surfaceAt(progress:real):color{const p=Math.max(0,Math.min(1,progress)),a=Theme.islandGround,b=root.activeSurface;return Qt.rgba(a.r+(b.r-a.r)*p,a.g+(b.g-a.g)*p,a.b+(b.b-a.b)*p,a.a+(b.a-a.a)*p)}
    readonly property real progress: movementAt(timeline)
    // Always land exactly at the endpoints. Strength zero keeps a smooth glide.
    function movementAt(t: real): real {
        if (t <= 0) return 0
        if (t >= 1) return 1
        const style = SettingsService.lockAnimationMovement
        const glide = 1 - Math.pow(1-t, 3)
        if (style === "glide") return glide
        if (style === "quint") return 1-Math.pow(1-t,5)
        if (style === "linear") return t
        const amount = Math.max(0, Math.min(1, SettingsService.lockAnimationBounciness/100))
        const rebounds = Math.max(1, Math.min(3, SettingsService.lockAnimationRebounds))
        if (style === "spring") {
            const damping = 8.5
            const frequency = (rebounds + 0.5) * Math.PI * 2
            const wave = (v) => 1 - Math.exp(-damping*v)
                * (Math.cos(frequency*v) + damping/frequency * Math.sin(frequency*v))
            return glide*(1-amount) + wave(t)/wave(1)*amount
        }
        if (style === "bounce") {
            // Repeated, damped rebounds after the initial descent.
            const hit = 0.55
            const bounce = t < hit ? Math.pow(t/hit, 2)
                : 1 - 0.20*Math.pow((1-t)/(1-hit), 2)
                  * Math.abs(Math.sin((t-hit)/(1-hit)*Math.PI*rebounds))
            return glide*(1-amount) + bounce*amount
        }
        return t < 0.5 ? 4*t*t*t : 1 - Math.pow(-2*t+2, 3)/2
    }
    readonly property bool slide: SettingsService.lockAnimation === "bar-slide"
    readonly property real islandWidth: LockStyleService.values.lockIslandWidth
    readonly property real islandHeight: LockStyleService.values.lockIslandHeight
    readonly property real islandLeft: (width-islandWidth)/2 + LockStyleService.values.lockIslandOffset
    readonly property real islandTop: LockStyleService.values.lockIslandTop
    readonly property real barRadius:{
        const scale=Theme.barScale,nativeHeight=root.islandHeight/scale
        const wanted=SettingsService.notched&&SettingsService.notchCornerRadius>=0?SettingsService.notchCornerRadius:SettingsService.moduleRadius("bar",SettingsService.islandChipsEnabled&&IslandChipService.get("clock").style==="rounded"?10:Math.min(nativeHeight/2,Theme.radiusLarge+4))
        return Math.max(0,Math.min(root.islandHeight/2,wanted*scale))
    }
    readonly property real barShoulder:Math.max(0,Math.min(SettingsService.notchShoulderRadius*Theme.barScale,root.islandHeight-root.barRadius))
    // The Island leads the bottom edge of the incoming full-screen sheet.
    readonly property real leaderY: islandTop + progress * (height + islandHeight + 20 - islandTop)
    visible: SettingsService.lockIslandEnabled
    function seek(value: real): void { movement.stop(); timeline = Math.max(0, Math.min(1, value)) }
    function prepare():void { movement.stop();morphing.stop();seal.reset();timeline=0;morph=0 }
    function replay():void {
        root.prepare();movement.start();morphing.start()
        if(!root.leaving)seal.start()
    }
    LockBarSeal {
        id:seal
        enabled:root.morphStyle!=="none"&&SettingsService.lockAnimation!=="none"
        revealDuration:root.slide?movement.duration:morphing.duration
        openHold:Math.round(SettingsService.lockIslandOpenHold*Theme.motion)
        closeDuration:Math.round(SettingsService.lockIslandCloseDuration*Theme.motion)
    }
    onLeavingChanged: if(root.preview || LockService.secure) replay()
    Connections {
        target:LockService
        // Surfaces may survive an unlock. Reset before they map again so a
        // completed padlock from the previous cycle cannot flash on first paint.
        function onPendingLockChanged():void{if(!root.preview && LockService.pendingLock)root.prepare()}
        function onSecureChanged():void{if(!root.preview && LockService.secure)root.replay()}
    }
    Component.onCompleted: if(root.preview || LockService.secure)replay()
    NumberAnimation {
        id: movement
        target: root; property: "timeline"; from: 0; to: 1
        duration: Math.round(SettingsService.lockDuration * Theme.motion)
        easing.type: Easing.Linear
    }
    NumberAnimation{
        id:morphing;target:root;property:"morph";from:0;to:1
        duration:root.morphStyle==="none"?0:Math.min(SettingsService.lockIslandTransitionDuration,Math.round(SettingsService.lockDuration*Theme.motion))
        easing.type:root.morphStyle==="fade"?Easing.Linear:root.leaving?Easing.InOutCubic:Easing.OutCubic
    }
    component IslandBody:PowerRectangle {
        width:root.islandWidth;height:root.islandHeight
        radius:root.barRadius
        roundingPower:SettingsService.notched?Theme.notchRoundingPower:2
        topLeftRadius:SettingsService.notched?0:radius
        topRightRadius:SettingsService.notched?0:radius
        color:Theme.islandGround;border.color:Theme.islandRim;border.width:SettingsService.notched?0:1
        NotchFillet {anchors.right:parent.left;anchors.top:parent.top;width:root.barShoulder;height:width;mirrored:true;color:parent.color;visible:SettingsService.notched}
        NotchFillet {anchors.left:parent.right;anchors.top:parent.top;width:root.barShoulder;height:width;color:parent.color;visible:SettingsService.notched}
    }
    IslandBody {
        x: root.islandLeft; y: root.islandTop
        opacity:root.slide?(root.leaving?0:Math.max(0,(root.timeline-.9)/.1)):1
        color:root.slide?Theme.islandGround:root.surfaceAt(root.activeOpacity)
        IslandRest{
            id:activeFace
            width:ModuleService.restWidth
            height:Theme.capsuleHeight
            anchors.centerIn:parent
            ModuleElementStyler{target:activeFace;moduleId:"bar"}
            visible:!root.slide&&!root.capturedBar&&opacity>0
            opacity:root.activeOpacity
            scale:root.contentScale*Theme.barScale
            transform:Translate{y:root.contentOffset}
            enabled:false
        }
        Padlock {
            anchors.centerIn:parent
            tint:Theme.text
            // Show a fully open padlock first, then close it after the handoff.
            animateLift:false
            opened:root.desktopEntry?LockMotionService.unlocking:root.leaving
            lift:root.leaving?(root.desktopEntry?LockMotionService.shackleLift:Math.max(0,Math.min(1,root.phase/.35))):seal.lift
            opacity:root.slide?1:root.symbolOpacity
            scale:.8*Theme.barScale
        }

    }
    IndividualIslandChips{
        anchors.fill:parent
        visible:SettingsService.islandChipsEnabled&&!root.slide&&!root.capturedBar&&opacity>0
        configuration:SettingsService
        preview:false
        clockCenter:root.islandLeft+root.islandWidth/2
        clockWidth:root.islandWidth
        clockY:root.islandTop
        clockHeight:root.islandHeight
        opacity:root.activeOpacity
        enabled:false
    }
    IslandBody {
        visible: root.slide && root.timeline < 1
        x: root.islandLeft
        y: root.leaderY
        opacity: 1
        IslandRest {width:ModuleService.restWidth;height:Theme.capsuleHeight;anchors.centerIn:parent;scale:Theme.barScale;visible:!root.leaving;enabled:false}
        Padlock { visible: root.leaving; anchors.centerIn: parent; tint: Theme.text; opened: true; scale: 0.8*Theme.barScale }
    }
}
