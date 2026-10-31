pragma Singleton
import QtQuick
import Quickshell
QtObject {
    id:root
    property bool started:false
    property bool starting:false
    property bool unlocking:false
    // Exactly one surface owns each unlock: the secure surface with a desktop
    // snapshot, or the live desktop bar once authentication releases the lock.
    property bool sessionUnlock:false
    property bool waitingForDesktop:false
    property real shackleLift:0
    readonly property bool desktopAnimating:root.starting&&!root.sessionUnlock
    readonly property int totalDuration:Math.max(0,SettingsService.barEntryHold)+Math.max(0,SettingsService.barEntryUnlockLead)+Math.max(0,SettingsService.barEntryDuration)
    property real progress:1
    readonly property real alpha:Math.max(0,Math.min(1,(root.progress-.35)/.65))
    readonly property real symbolAlpha:Math.max(0,Math.min(1,1-root.progress/.35))
    readonly property real contentScale:SettingsService.barEntryAnimation==="bounce"?.84+.16*root.progress:SettingsService.barEntryAnimation==="smooth"?.96+.04*root.progress:1
    readonly property real contentOffset:SettingsService.barEntryAnimation==="bounce"?8*(1-root.progress):SettingsService.barEntryAnimation==="smooth"?4*(1-root.progress):0
    readonly property PersistentProperties memory:PersistentProperties{
        reloadableId:"hyprland-bar-entry"
        property bool played:false
        onLoaded:Qt.callLater(root.start)
        onReloaded:{root.started=true;root.starting=false;root.progress=1}
    }
    function start():void {
        if(root.started||!SettingsService.arrived)return
        // Prepare the first frame before exposing any desktop surface.
        if(!memory.played&&SettingsService.lockIslandEnabled&&Quickshell.env("IMPASTO_SESSION_BOOT")==="1")root.preview()
        memory.played=true
        root.started=true
    }
    function cancel():void {
        hold.stop();unlockLead.stop();reveal.stop();shackle.stop()
        root.waitingForDesktop=false;root.shackleLift=0
        root.starting=false;root.unlocking=false;root.progress=1;root.sessionUnlock=false
    }
    function run(fromLock:bool):int {
        root.cancel()
        if(!SettingsService.barEntryEnabled||SettingsService.barEntryAnimation==="none")return 0
        root.sessionUnlock=fromLock
        root.progress=0;root.unlocking=false;root.starting=true
        hold.restart()
        return root.totalDuration
    }
    function preview():void { root.run(false) }
    function beginUnlock(onDesktop:bool):int {
        if(!SettingsService.barEntryOnUnlock||!SettingsService.lockIslandEnabled||(SettingsService.lockAnimation==="bar-slide"&&!onDesktop)){
            root.cancel();return 0
        }
        const duration=root.run(!onDesktop)
        if(onDesktop&&root.starting){hold.stop();root.waitingForDesktop=true}
        return duration
    }
    function resumeDesktopUnlock():void {
        if(!root.waitingForDesktop||!root.starting)return
        root.waitingForDesktop=false;hold.restart()
    }
    readonly property NumberAnimation shackle:NumberAnimation {
        target:root;property:"shackleLift";from:0;to:1
        duration:Math.max(0,SettingsService.barEntryUnlockLead)
        easing.type:Easing.InOutCubic
    }
    readonly property Timer hold:Timer{interval:SettingsService.barEntryHold;onTriggered:{root.unlocking=true;shackle.restart();unlockLead.restart()}}
    readonly property Timer unlockLead:Timer{interval:SettingsService.barEntryUnlockLead;onTriggered:reveal.start()}
    readonly property NumberAnimation reveal:NumberAnimation{
        target:root;property:"progress";from:0;to:1;duration:SettingsService.barEntryDuration
        easing.type:SettingsService.barEntryAnimation==="bounce"?Easing.OutBack:SettingsService.barEntryAnimation==="smooth"?Easing.OutCubic:Easing.Linear
        easing.overshoot:.9
        onFinished:root.starting=false
    }
    readonly property Connections settings:Connections{target:SettingsService;function onArrivedChanged(){Qt.callLater(root.start)}}
    Component.onCompleted:Qt.callLater(root.start)
}
