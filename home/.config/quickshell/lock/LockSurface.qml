// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   L O C K   S U R F A C E                                                │
// │   lock surface for one screen · active wallpaper behind                  │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Window
import QtQuick.Effects

import "../theme"
import "../services"
import "../bar/widgets"
import "common"

// One screen of the lock: the active wallpaper blurred behind the clock and
// battery; while music plays,
// the clock small at the top and the player in the middle, its cover blurred
// behind if that is the setting. A key or a click wakes
// it: the clock rises and the account, the field and the power buttons come
// in underneath; Escape or a while untouched sends them away again. Blurred
// enough that text on the desktop cannot be read.
Item {
    id: root

    signal submitted(string password)

    property string output: ""
    clip: true
    readonly property bool fullSlide: SettingsService.lockAnimation === "bar-slide" && root.desktopReady
    readonly property real contentHeld: root.fullSlide ? 1 : root.held
    // MultiEffect's first nonzero blur level still downsamples the source.
    // Blend that last small radius into the original pixels, rather than
    // switching from the minimum blur straight to a sharp desktop at zero.
    readonly property real sharpBlend: {
        const t=Math.max(0,Math.min(1,root.contentHeld/.2))
        return 1-t*t*(3-2*t)
    }
    readonly property real incomingY: Math.min(0, -root.height + islandTransition.leaderY + islandTransition.islandHeight)

    // Focus lands here and stays.
    function claim(): void {
        account.claim()
    }

    // The first presented secure frame is the animation's starting frame.
    property bool firstFramePresented:false
    property real firstPresentedProgress:-1
    property bool unlockFrameReported:false
    property int fadeFrameCount:0
    property real fadeWorstMs:0
    property double fadeStartedAt:0
    property string fadePhase:"lock"
    Connections {
        target:root.Window.window
        function onFrameSwapped():void {
            if(LockService.locked&&!root.firstFramePresented){
                root.firstPresentedProgress=root.held
                root.firstFramePresented=true
            }
            if(LockService.locked&&LockService.leaving&&!lockFade.running&&root.held<=.0001&&!root.unlockFrameReported){
                root.unlockFrameReported=true
                Qt.callLater(()=>LockService.unlockFramePresented(root.output))
            }
        }
    }
    Connections {
        target:LockService
        function onLockedChanged():void {
            if(!LockService.locked){root.firstFramePresented=false;root.firstPresentedProgress=-1;root.unlockFrameReported=false}
        }
    }
    Connections {
        target:lockFade
        function onRunningChanged():void {
            if(lockFade.running){
                root.fadePhase=LockService.leaving?"unlock":"lock"
                root.fadeStartedAt=Date.now();root.fadeFrameCount=0;root.fadeWorstMs=0
            }else if(root.fadeFrameCount>0){
                const report={output:root.output,frames:root.fadeFrameCount,worstMs:root.fadeWorstMs,elapsedMs:Date.now()-root.fadeStartedAt,firstPresentedProgress:root.firstPresentedProgress,end:root.held,desktopReady:root.desktopReady}
                LockService.lastFadeReports=Object.assign({},LockService.lastFadeReports,{[root.fadePhase]:report})
            }
        }
    }
    FrameAnimation {
        running:lockFade.running
        onTriggered:{root.fadeFrameCount++;root.fadeWorstMs=Math.max(root.fadeWorstMs,frameTime*1000)}
    }
    readonly property real held:lockFade.value
    LockFadeState {
        id:lockFade
        locked:LockService.locked
        secure:LockService.secure
        presented:root.firstFramePresented
        leaving:LockService.leaving
        directDesktop:LockService.unlockToDesktop
        duration:LockService.fadeDuration
        curve:{
            const style=LockService.leaving&&SettingsService.lockUnlockMovement!=="follow"?SettingsService.lockUnlockMovement:SettingsService.lockAnimationMovement
            return style==="quint"?Easing.OutQuint:style==="glide"?Easing.OutCubic:style==="linear"?Easing.Linear:Easing.InOutSine
        }
    }

    readonly property bool desktopReady: LockService.shotReady
        && desktopShot.status === Image.Ready
    readonly property bool desktopTransition: LockService.shotReady
        && root.desktopReady && (LockService.locked || LockService.leaving)

    // 0 at rest, 1 awake: stronger wallpaper blur while entering a password.
    property real awake: LockService.awake ? 1 : 0

    Behavior on awake {
        NumberAnimation { duration: Theme.durationMorph; easing.type: Theme.easing }
    }

    // Show the configured lock player when media is available; its clock
    // moves up as the player takes the space below it.
    readonly property bool music: SettingsService.lockMusic !== "off" && MediaService.available
    property real musical: root.music ? 1 : 0

    Behavior on musical {
        NumberAnimation { duration: Theme.durationMorph; easing.type: Theme.easing }
    }

    // A screen put back to rest takes its half-typed password with it.
    Connections {
        target: LockService
        function onAwakeChanged(): void {
            if (!LockService.awake)
                account.clear()
        }
    }

    // The pointer moving on an awake screen is a reason to look for a face
    // again; a click wakes the screen as a key does. Qt sends a hover at the resting
    // position whenever the scene repaints, so only a pointer that has moved
    // counts.
    HoverHandler {
        property point last: Qt.point(-1, -1)

        onPointChanged: {
            const at = point.position
            const moved = last.x >= 0 && Math.abs(at.x - last.x) + Math.abs(at.y - last.y)
                > Qt.styleHints.startDragDistance
            if (last.x < 0 || moved)
                last = at
            if (moved)
                LockService.wake()
        }
    }

    TapHandler {
        onTapped: {
            LockService.rouse()
            account.claim()
        }
    }

    // The desktop remains below the incoming lock, then slides over it on unlock.
    Image {
        id: movingDesktop
        objectName: "slide-desktop"
        width: root.width; height: root.height
        source: SettingsService.lockAnimation==="bar-slide"?LockService.desktopSource(root.output):""
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: true
        visible: root.fullSlide && status === Image.Ready
        z: LockService.leaving ? 2 : 0
        y: LockService.leaving && root.fullSlide ? root.incomingY : 0
    }

    Item {
        id: lockScene
        objectName: "slide-lock"
        width: root.width; height: root.height
        z: 1
        y: root.fullSlide && !LockService.leaving ? root.incomingY : 0
        // ── BACKGROUND ──────────────────────────────────────────────────────────

        Image {
            id: wallpaper

            anchors.fill: parent
            source:SettingsService.lockBackdrop==="desktop"&&LockService.shotReady?LockService.desktopSource(root.output):WallpaperService.currentWallpaper
            visible:false
            sourceSize:WallpaperService.lockImageSize(root.output)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }

        MultiEffect {
            anchors.fill: parent
            source: wallpaper
            visible: wallpaper.status === Image.Ready
            opacity:1
            autoPaddingEnabled:false
            blurEnabled:radiusWanted>0
            blur: root.contentHeld
            // Keep the wallpaper recognizable at rest; increase blur while awake.
            readonly property real radiusWanted:SettingsService.lockBlur * (0.4 + SettingsService.lockExtraBlur / 100 * root.awake)
            blurMax:Math.max(1,Math.min(64,radiusWanted))
            blurMultiplier:Math.max(1,radiusWanted/64)
            // Barely darkened: a dark desktop dimmed further looks broken. The text
            // has its own shadow and every capsule is opaque, so the background
            // only needs to be blurred.
            brightness: -0.05 * root.contentHeld * SettingsService.lockDim / 18
            saturation:SettingsService.lockVibrance/100*root.contentHeld
        }

        // Wallpaper mode crossfades from the desktop. Desktop mode blurs the
        // same captured pixels directly, without a sharp overlay hiding the blur.
        Item{
            id:desktopViewport
            readonly property real crop:0
            anchors.fill:parent;anchors.topMargin:crop;clip:true
        Image {
            id: desktopShot

            width:root.width;height:root.height;y:-desktopViewport.crop
            source: LockService.desktopSource(root.output)
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            cache: true
            visible: status === Image.Ready
            opacity:root.fullSlide?0:SettingsService.lockBackdrop==="desktop"&&wallpaper.status===Image.Ready?root.sharpBlend:root.desktopTransition?1-root.held:0
        }

        }

        // While music plays, its cover can stand in for the desktop: blurred to a
        // wash of its colours, darkened enough for white type, and gone as the
        // lock lets go, so the desktop is still what is left. Drawn at a tenth of
        // the screen, blurred there and stretched, so the blur reaches ten times
        // as far.
        Item {
            id: wash

            width: Math.ceil(root.width / 10)
            height: Math.ceil(root.height / 10)
            scale: 10
            transformOrigin: Item.TopLeft
            visible: opacity > 0
            opacity: cover.status === Image.Ready ? root.musical * root.contentHeld : 0
            layer.enabled: true
            layer.smooth: true

            Behavior on opacity {
                NumberAnimation { duration: Theme.durationMorph; easing.type: Theme.easing }
            }

            Image {
                id: cover

                anchors.fill: parent
                source: SettingsService.lockMusicGround === "cover" && root.music ? MediaService.artUrl : ""
                visible: false
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 96
                sourceSize.height: 96
            }

            MultiEffect {
                anchors.fill: parent
                source: cover
                blurEnabled: true
                blur: 1
                blurMax: 24
                brightness: -0.28
                saturation: 0.25
                autoPaddingEnabled: false
            }
        }

        // The lightest of washes, for separation rather than contrast.
        Rectangle {
            anchors.fill: parent
            color: Theme.scrim
            opacity: SettingsService.lockDim / 100 * root.contentHeld
        }

        // ── STATUS ──────────────────────────────────────────────────────────────

        ReferenceStatus {
            visible:SettingsService.lockStatus&&SettingsService.lockDesign==="reference"
            anchors.right:parent.right;anchors.rightMargin:26;anchors.top:parent.top;anchors.topMargin:20
            width:implicitWidth;height:implicitHeight;percent:BatteryService.percent;batteryAvailable:BatteryService.available
            ink:LockStyleService.values.lockTextColor;opacity:.8*root.contentHeld
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 28
            anchors.top: parent.top
            anchors.topMargin: 18
            spacing: 12
            visible: SettingsService.lockStatus&&SettingsService.lockDesign!=="reference"
            opacity: 0.82 * root.contentHeld

            Text {
                visible: BatteryService.available
                text: BatteryService.icon + "  " + BatteryService.percent + "%"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: LockStyleService.values.lockTextColor
            }
            Text {
                text: NetworkService.icon
                font.family: Theme.fontMono
                font.pixelSize: 15
                color: LockStyleService.values.lockTextColor
            }
        }

        // ── CLOCK ───────────────────────────────────────────────────────────────
        //
        // The clock stays fixed at the top while the account is active.

        Item {
            id: face

            readonly property real restY: SettingsService.lockClockTop
            readonly property real awakeY: face.restY
            readonly property real plainY: face.restY
            readonly property real plainScale: 1
            // With music, where it is awake whether awake or not — below the
            // island opened for a face — and no taller than 380.
            readonly property real musicY: face.awakeY
            readonly property real musicScale: Math.min(0.9, 380 / Math.max(1, clock.height))

            anchors.horizontalCenter: parent.horizontalCenter
            y: face.plainY + (face.musicY - face.plainY) * root.musical
                + (SettingsService.lockAnimation === "soft-slide" ? (1-root.contentHeld)*24 : 0)
            width: clock.width
            height: clock.height
            opacity: root.contentHeld
            scale: face.plainScale + (face.musicScale - face.plainScale) * root.musical
            transformOrigin: Item.Top


            LockClock {
                id: clock
                style: SettingsService.lockClock
            }
        }

        // ── MUSIC ───────────────────────────────────────────────────────────────
        //
        // In the room between the clock and the account, centred in it.

        Loader {
            id: music

            readonly property real roomTop: face.musicY + clock.height * face.musicScale
            readonly property real roomBottom: account.y

            // A short screen has less room than the player: it is drawn smaller
            // to fit, never under the account.
            readonly property real fit: music.item
                ? Math.min(1, Math.max(0, music.roomBottom - music.roomTop - 24) / Math.max(1, music.item.implicitHeight))
                : 1

            active: LockService.locked && (root.music || root.musical > 0)
            asynchronous: true
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(music.roomTop + (music.roomBottom - music.roomTop - height) / 2)
            scale: music.fit
            opacity: root.musical * root.contentHeld
            visible: opacity > 0

            sourceComponent: LockMedia {
                lyrics: SettingsService.lockMusic === "lyrics" && SettingsService.lyrics
            }
        }

        // ── ACCOUNT ─────────────────────────────────────────────────────────────

        // The profile stays visible at rest; the keyboard stays focused in the
        // field, which appears when the lock wakes.
        LockAccount {
            id: account
            glassSource:wallpaper

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: SettingsService.lockAccountBottom
            opacity: root.contentHeld

            onSubmitted: password => root.submitted(password)
        }

        // ── POWER ───────────────────────────────────────────────────────────────
        //
        // Bottom left at the bar's margin, where the login screen has the same
        // buttons, and only while awake.
    }

        LockCapturedBar {
            anchors.top:parent.top;anchors.left:parent.left;anchors.right:parent.right
            height:Math.ceil(islandTransition.islandTop+islandTransition.islandHeight+2)
            fullHeight:root.height
            source:LockService.desktopSource(root.output)
            barX:islandTransition.islandLeft;barY:islandTransition.islandTop
            barWidth:islandTransition.islandWidth;barHeight:islandTransition.islandHeight
            cornerRadius:islandTransition.barRadius
            cornerPower:SettingsService.notched?Theme.notchRoundingPower:2
            shoulder:islandTransition.barShoulder;notched:SettingsService.notched
            visible:root.desktopTransition&&!root.fullSlide&&SettingsService.lockIslandEnabled&&opacity>0
            opacity:islandTransition.activeOpacity
            z:4
        }

    LockIslandTransition {
        id: islandTransition
        objectName: "slide-island"
        anchors.fill: parent
        held: root.held
        capturedBar:root.desktopReady&&!root.fullSlide
        z: 3
    }
}
