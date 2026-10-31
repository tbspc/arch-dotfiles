// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   L O C K   S E R V I C E                                                │
// │   session lock state · background capture and authentication             │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

import "../theme"

// Locks through ext-session-lock. The resting lock shows WallpaperService's
// active wallpaper; a private pre-lock desktop frame is used only to crossfade
// back to the live desktop during unlock.
//
// The password is handed straight to PAM's `respond` and never stored past
// the field it is typed in, which every screen shares and which empties on
// sending, on rest and on unlock. A face
// is a second PAM conversation beside it, where `./setup face` has put howdy.
Singleton {
    id: root

    property bool locked: false

    // Give both the background and controls time to ease fully out before
    // the compositor releases the secure session-lock surface.
    readonly property int fadeDuration:Math.round((SettingsService.lockAnimation==="none"?0:root.leaving&&SettingsService.lockUnlockDuration>0?SettingsService.lockUnlockDuration*100/Math.max(50,Math.min(200,SettingsService.lockAnimationSpeed)):SettingsService.lockDuration)*Theme.motion)

    // `locked` is the request; this is the compositor confirming the screen
    // is covered.
    property bool secure: false
    // Start the desktop-owned animation once the compositor has released the
    // secure surface, without resetting or replaying its prepared state.
    onSecureChanged:if(!root.secure&&!root.locked)LockMotionService.resumeDesktopUnlock()
    onLockedChanged:if(!root.secure&&!root.locked)LockMotionService.resumeDesktopUnlock()

    property bool authenticating: false
    property string message: ""
    property bool failed: false

    // From the moment the lock is answered until the surface has let go of
    // the desktop; `locked` falls after it.
    property bool leaving: false
    property int unlockBarDuration: 0
    property bool unlockToDesktop: false
    property var pendingUnlockOutputs:[]
    property string unlockReleaseKind:""
    readonly property bool frameDrivenUnlock:!root.unlockToDesktop&&["fade","soft-slide"].includes(SettingsService.lockAnimation)
    function unlockFramePresented(output:string):void {
        if(!root.locked||!root.leaving||!root.frameDrivenUnlock)return
        root.pendingUnlockOutputs=root.pendingUnlockOutputs.filter(name=>name!==output)
        root.tryCompleteUnlock()
    }
    function tryCompleteUnlock():void {
        if(root.locked&&root.leaving&&root.frameDrivenUnlock&&root.pendingUnlockOutputs.length===0&&(!root.unlockBarDuration||!LockMotionService.starting))root.finishUnlock("presented")
    }
    function finishUnlock(reason:string):void {
        if(!root.locked||!root.leaving)return
        root.leave.stop();root.unlockReleaseKind=reason
        if(root.pam.active)root.pam.abort()
        if(root.face.active)root.face.abort()
        root.faceHoldTimer.stop();root.locked=false
        root.rest();root.forget();root.unlocked()
    }
    readonly property Connections unlockBarFinished:Connections {
        target:LockMotionService
        function onStartingChanged():void {if(!LockMotionService.starting)root.tryCompleteUnlock()}
    }

    // Two stages, shared by every screen: at rest the clock alone, awake the
    // account, the field and the power buttons. A key or a click wakes it,
    // Escape or a while untouched puts it back.
    property bool awake: false

    // What is typed, one field for every screen: each surface shows it and
    // writes to it, so the dots are the same wherever the keyboard is.
    property string typed: ""

    // How long an awake screen waits untouched before going back to its
    // clock.
    readonly property int awakeFor: 30000

    readonly property string shotDirectory:
        `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/quickshell`

    property int shotSerial: 0
    property int captureSerial: 0
    property bool frameHold:false
    property double frameUsableUntil:0
    onFrameHoldChanged:{
        if(root.frameHold)root.warmExpiry.stop()
        else if(root.shotReady){root.frameUsableUntil=Date.now()+2000;root.warmExpiry.restart()}
    }
    property bool shotReady: false
    property double shotCapturedAt: 0

    function shotPath(output: string): string {
        return `${root.shotDirectory}/unlock-${root.shotSerial}-${output}.ppm`
    }

    function desktopSource(output: string): string {
        if (!root.shotReady || !/^[A-Za-z0-9_.-]+$/.test(output))
            return ""
        return `file://${root.shotPath(output)}?v=${root.shotSerial}`
    }

    function rouse(): void {
        if (!root.locked || root.leaving)
            return
        root.awake = true
        root.drowse.restart()
        root.wake()
    }

    // Surfaces clear their field when this falls, and a scan under way stops.
    function rest(): void {
        root.drowse.stop()
        root.awake = false
        root.typed = ""
        if (root.face.active)
            root.face.abort()
        root.faceScanning = false
        root.failed = false
        root.message = ""
    }

    readonly property Timer drowse: Timer {
        interval: root.awakeFor
        // A password being checked is not a screen left alone.
        onTriggered: root.authenticating ? root.drowse.restart() : root.rest()
    }

    signal unlocked()

    // ── LOCKING ─────────────────────────────────────────────────────────────

    // Kept for the shell binding; locking no longer waits for animated panel geometry.
    property bool shellQuiet: true

    property bool pendingLock: false

    signal cleaningForLock()
    property bool preparingFrame:false
    property bool cleanFrameNeeded:false
    readonly property Timer cleanFrameTimer:Timer {
        interval:16
        onTriggered:{if(root.capture.running)return;root.cleanFrameNeeded=false;root.prefetchDesktop()}
    }
    property bool waitingForFrame:false
    property double captureStartedAt:0
    property double lastCaptureMs:0
    property bool lastLockHadDesktop:false
    property var lastFadeReports:({})
    readonly property Timer frameDeadline:Timer{interval:250;onTriggered:root.commitLock()}
    function lock():void {
        if(root.locked||root.pendingLock||root.waitingForFrame)return
        root.preparingFrame=true;root.cleanFrameNeeded=false
        root.cleaningForLock()
        if(root.cleanFrameNeeded){
            root.shotReady=false;root.waitingForFrame=true
            root.cleanFrameTimer.restart();root.frameDeadline.restart();return
        }
        root.preparingFrame=false
        if(root.shotReady&&(root.frameHold||Date.now()<root.frameUsableUntil)){
            root.commitLock();return
        }
        // Direct shortcuts have no menu hover to prewarm their frame. Capture
        // once, with a hard deadline; menu/button locks use the ready frame.
        root.waitingForFrame=true
        root.prefetchDesktop()
        root.frameDeadline.restart()
    }
    function commitLock():void {
        root.waitingForFrame=false;root.frameDeadline.stop();root.cleanFrameTimer.stop();root.preparingFrame=false;root.cleanFrameNeeded=false
        if (root.locked || root.pendingLock)return
        LockMotionService.cancel()
        root.unlockBarDuration=0
        root.unlockToDesktop=false
        root.message="";root.failed=false;root.leaving=false
        root.rest()
        root.faceScanning=false;root.faceMatched=false
        root.eraseAfterUnlock.stop();root.warmExpiry.stop()
        // A recent prewarmed frame is optional. Never wait for a screenshot,
        // panel animation, external process or timeout before requesting the lock.
        root.shotReady=root.shotReady && (root.frameHold||Date.now()<root.frameUsableUntil)
        root.lastLockHadDesktop=root.shotReady
        root.pendingLock=true
        root.locked=true
        root.pendingLock=false
        root.faceMisses=0;root.faceQuietUntil=0
        root.begin()
        root.faceCheck.running=true
        FaceService.refresh()
    }

    function prefetchDesktop():void {
        if(root.locked||root.pendingLock||root.capture.running)return
        // One capture on approaching a lock control, with no idle polling.
        if(root.shotReady&&Date.now()-root.shotCapturedAt<250)return
        root.eraseAfterUnlock.stop();root.warmExpiry.stop()
        // Keep the last complete frame while its replacement is captured.
        root.captureSerial=Math.max(root.captureSerial,root.shotSerial)+1
        root.captureStartedAt=Date.now()
        root.capture.command=["sh","-c",root.captureScript()]
        root.capture.running=true
    }
    function captureFinished(code:int):void {
        root.lastCaptureMs=Date.now()-root.captureStartedAt
        if(root.cleanFrameNeeded){root.cleanFrameTimer.restart();return}
        // Late frames cannot change the background during the lock animation.
        if(root.locked||root.pendingLock)return
        if(code===0){
            root.shotCapturedAt=Date.now();root.frameUsableUntil=Date.now()+2000
            root.shotSerial=root.captureSerial;root.shotReady=true
        }
        if(root.waitingForFrame){root.commitLock();return}
        if(!root.frameHold)root.warmExpiry.restart()
    }
    readonly property Timer warmExpiry:Timer {
        interval:2000
        onTriggered:if(!root.locked&&!root.pendingLock&&!root.frameHold){root.shotReady=false;root.eraser.running=true}
    }

    function captureScript(): string {
        const screens = Quickshell.screens.filter(screen => /^[A-Za-z0-9_.-]+$/.test(screen.name))
        const shots = screens.map(screen => {
            const path = `${root.shotDirectory}/unlock-${root.captureSerial}-${screen.name}.ppm`
            return `(if timeout -k 0.05 2 grim -t ppm -o '${screen.name}' '${path}.tmp'; then mv -f '${path}.tmp' '${path}'; else rm -f '${path}.tmp'; fi) &`
        })
        const checks = screens.map(screen => `test -s '${root.shotDirectory}/unlock-${root.captureSerial}-${screen.name}.ppm'`)
        return `umask 077; mkdir -p '${root.shotDirectory}' || exit; for shot in '${root.shotDirectory}'/unlock-*.ppm '${root.shotDirectory}'/unlock-*.jpg; do case "$shot" in '${root.shotDirectory}/unlock-${root.shotSerial}-'*.ppm) ;; *) rm -f -- "$shot";; esac; done; ${shots.join(" ")} wait; ${checks.join(" && ") || "false"}`
    }

    readonly property Process capture: Process {
        onExited: (code, status) => root.captureFinished(code)
    }

    function forget(): void {
        root.typed = ""
        root.eraseAfterUnlock.restart()
    }

    readonly property Timer eraseAfterUnlock: Timer {
        interval: 1000
        onTriggered: { root.shotReady=false;root.eraser.running=true }
    }

    readonly property Process eraser: Process {
        command: ["sh", "-c", `rm -f '${root.shotDirectory}'/unlock-*.ppm '${root.shotDirectory}'/unlock-*.jpg`]
    }

    // ── AUTHENTICATING ──────────────────────────────────────────────────────

    // A PAM conversation ends after a refusal, so every attempt starts a new
    // one.
    function begin(): void {
        if (pam.active)
            pam.abort()
        root.authenticating = false
        pam.start()
    }

    function submit(password: string): void {
        if (root.authenticating || root.leaving)
            return
        // Enter on an empty field asks for the camera instead.
        if (password === "") {
            root.scan()
            return
        }
        root.failed = false
        root.message = ""

        // PAM has normally asked by now. If not, restart it and let the user
        // retry rather than keep the password around until it does.
        if (!pam.responseRequired) {
            root.begin()
            root.message = "Not ready — press Enter again"
            return
        }

        root.authenticating = true
        pam.respond(password)
    }

    readonly property PamContext pam: PamContext {
        // The same stack hyprlock's PAM file includes.
        config: "login"

        onCompleted: result => {
            root.authenticating = false
            if (result === PamResult.Success) {
                root.release()
                return
            }
            // The face got there first; the lock is already on its way out.
            if (root.leaving || root.faceMatched)
                return
            root.failed = true
            root.message = result === PamResult.MaxTries
                ? "Too many attempts"
                : "Wrong password"
            root.begin()
        }

        onError: error => {
            root.authenticating = false
            root.failed = true
            root.message = "Authentication is unavailable"
            console.warn("PAM error while unlocking:", error)
        }
    }

    // ── FACE ────────────────────────────────────────────────────────────────

    // A PAM service of its own, `impasto-face`, beside the password and never
    // inside `login`: a face that is not recognised does not count against
    // the password's attempts, and the password never waits for the camera.
    // Ready where `./setup system` put the service and `./setup face` put howdy,
    // and a face has been enrolled — when the list could be read at all.
    property bool facePam: false
    readonly property bool faceReady: root.facePam
        && (!FaceService.listed || FaceService.faces.length > 0)

    // From howdy's first message, which is the camera coming on, until the
    // scan ends. A refusal with nothing said first is howdy declining to look
    // (no face enrolled, the lid shut), and shows nothing.
    property bool faceScanning: false
    property bool faceMatched: false
    signal faceMissed()

    // A scan starts only on an awake screen — on waking it, by a key, a click
    // or the lid, or on the pointer while it is — never on its own: the camera would otherwise
    // find the face that has just locked the screen.
    // A miss rests long enough for its shake to be seen, and after three only
    // Enter on an empty field asks again.
    readonly property int faceRest: 1500
    readonly property int faceIdle: 5000
    readonly property int faceTries: 3
    property int faceMisses: 0
    property real faceQuietUntil: 0

    // How long the ring holds a match before the lock lets go.
    readonly property int faceHold: 650

    function wake(): void {
        if (!root.awake || root.faceMisses >= root.faceTries || Date.now() < root.faceQuietUntil)
            return
        root.scan()
    }

    function scan(): void {
        if (!root.locked || !root.secure || !root.faceReady || root.leaving
                || root.faceMatched || root.face.active)
            return
        root.face.start()
    }

    readonly property Process faceCheck: Process {
        command: ["sh", "-c",
            "test -f /etc/pam.d/impasto-face && test -f /usr/lib/security/pam_howdy.so"]
        onExited: code => root.facePam = code === 0
    }

    readonly property PamContext face: PamContext {
        config: "impasto-face"

        onPamMessage: root.faceScanning = true

        onCompleted: result => {
            const looked = root.faceScanning
            root.faceScanning = false
            if (!root.locked || root.leaving || !root.awake)
                return
            if (result === PamResult.Success) {
                root.faceMatched = true
                root.faceHoldTimer.restart()
                return
            }
            root.faceQuietUntil = Date.now() + (looked ? root.faceRest : root.faceIdle)
            if (looked) {
                root.faceMisses += 1
                root.faceMissed()
            }
        }

        onError: error => console.warn("PAM error while looking for a face:", error)
    }

    readonly property Timer faceHoldTimer: Timer {
        interval: root.faceHold
        onTriggered: root.release()
    }

    // ── UNLOCKING ───────────────────────────────────────────────────────────

    // Both conversations end here. The surface relaxes its blur while
    // `leaving`, and the lock falls once it has.
    function release(): void {
        if(!root.locked||root.leaving)return
        root.unlockReleaseKind=""
        root.pendingUnlockOutputs=Quickshell.screens.map(screen=>screen.name)
        root.unlockToDesktop=!root.shotReady
        root.unlockBarDuration=LockMotionService.beginUnlock(root.unlockToDesktop)
        root.leaving=true
        root.leave.restart()
    }

    readonly property Timer leave:Timer {
        // The rendered clear frame releases normal fades. This deadline is
        // only a fallback if a display cannot report its final presentation.
        interval:root.unlockToDesktop?16:Math.max(root.fadeDuration,root.unlockBarDuration)+(root.frameDrivenUnlock?250:40)
        onTriggered:root.finishUnlock("deadline")
    }
}
