// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   W A L L P A P E R   S E R V I C E                                      │
// │   wallpaper listing and application                                      │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Qt.labs.folderlistmodel

// Lists the bundled wallpapers and the animated ones, and applies them. Emits
// `applied` instead of calling ThemeService, so the dependency only runs one
// way.
//
// An animated wallpaper is a video mpvpaper plays over a still of it (its
// poster) that awww shows. `currentWallpaper` is always a picture — the
// poster while a video plays — so everything that draws the wallpaper keeps
// drawing one kind of file; `currentMotion` is the video, or empty.
QtObject {
    id: root

    signal applied(string path)
    signal wallpaperRequested(string path)
    signal adaptiveWallpaperRequested(string path)
    signal pickerCloseRequested()

    readonly property string script: Quickshell.shellPath("scripts/theme_manager.py")

    // One native directory watch, with no image decoding or periodic polling.
    readonly property FolderListModel wallpaperFolder:FolderListModel {
        folder:"file://"+(Quickshell.env("XDG_DATA_HOME")||Quickshell.env("HOME")+"/.local/share")+"/wallpapers"
        showDirs:false;showHidden:false
        nameFilters:["*.jpg","*.jpeg","*.png","*.webp","*.JPG","*.JPEG","*.PNG","*.WEBP"]
        onCountChanged:directoryScanDelay.restart()
    }
    readonly property Timer directoryScanDelay:Timer{interval:100;onTriggered:root.scan()}
    property bool scanAgain:false
    property var wallpapers: []
    // `{ name, path, poster }`, from the `animated` folder beside the stills.
    property var animated: []
    property string currentWallpaper: ""
    property string currentMotion: ""
    property bool pickerClosing:false
    onPickerClosingChanged:if(!root.pickerClosing)Qt.callLater(root.startLoginSync)
    property bool scanning: false
    property bool wallpaperStateLoaded: false

    // What was picked: the video while one plays, else the picture. What a
    // profile keeps, and what the picker marks as applied.
    readonly property string chosen: root.currentMotion || root.currentWallpaper

    // Hold only the current lock wallpaper, decoded at each output's pixels.
    // Changing wallpaper replaces these images; there is no capture or polling.
    function lockImageSize(output:string):size {
        const screen=Quickshell.screens.find(s=>s.name===output)||Quickshell.screens[0]
        const ratio=screen?.devicePixelRatio||1
        return Qt.size(Math.max(1,Math.round((screen?.width||1920)*ratio)),Math.max(1,Math.round((screen?.height||1080)*ratio)))
    }
    readonly property Item lockImageCache:Item {
        visible:false
        Repeater {
            id:lockImages
            model:Quickshell.screens
            Image {
                required property var modelData
                width:modelData.width;height:modelData.height
                source:root.currentWallpaper
                sourceSize:root.lockImageSize(modelData.name)
                fillMode:Image.PreserveAspectCrop
                asynchronous:true;cache:true
            }
        }
    }
    function lockImagesReady():bool {
        if(!root.currentWallpaper||!lockImages.count)return false
        for(let i=0;i<lockImages.count;i++)if(lockImages.itemAt(i)?.status!==Image.Ready)return false
        return true
    }

    // Keep decoded picker images alive even while the picker is closed.
    // Prioritize its five visible cards, then the next neighbours for browsing.
    property var pickerPreviewPaths:[]
    readonly property size previewSize: Qt.size(320, 200)
    readonly property var previewPaths: {
        if(root.pickerPreviewPaths.length)return root.pickerPreviewPaths
        const list = root.wallpapers
        if (!root.wallpaperStateLoaded || !list || list.length === 0)
            return []
        const center = Math.max(0, list.findIndex(entry => entry.path === root.chosen))
        const paths = []
        for (const offset of [0, -1, 1, -2, 2, -3, 3, -4, 4]) {
            const entry = list[center + offset]
            if (entry)
                paths.push(entry.path)
        }
        return paths
    }

    readonly property Item previewCache: Item {
        visible: false
        Repeater {
            id: previewImages
            model: root.previewPaths

            Image {
                required property string modelData
                width: root.previewSize.width
                height: root.previewSize.height
                source: `file://${modelData}`
                sourceSize: root.previewSize
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }
        }
    }

    onPreviewPathsChanged:Qt.callLater(root.warmNearbyPalettes)
    function warmNearbyPalettes():void{root.warmPalettes(root.previewPaths.slice(0,5))}
    property string pendingPaletteWarm:""
    function warmPalettes(paths:var):void {
        if(!paths||!paths.length)return
        root.pendingPaletteWarm=JSON.stringify(paths)
        paletteWarmDelay.restart()
    }
    function warmNextPalette():void {
        if(paletteWarmProcess.running||root.pendingPaletteWarm==="")return
        paletteWarmProcess.command=[root.script,"cache-palettes",root.pendingPaletteWarm]
        root.pendingPaletteWarm=""
        paletteWarmProcess.running=true
    }
    readonly property Timer paletteWarmDelay:Timer{interval:60;onTriggered:root.warmNextPalette()}
    readonly property Process paletteWarmProcess:Process{onExited:root.warmNextPalette()}

    function previewReady(path: string): bool {
        for (let index = 0; index < previewImages.count; ++index) {
            const image = previewImages.itemAt(index)
            if (image && image.modelData === path)
                return image.status === Image.Ready
        }
        return false
    }

    readonly property var motionExtensions: /\.(mp4|webm|mkv|mov|gif)$/i

    function isMotion(path: string): bool {
        return root.motionExtensions.test(path)
    }

    readonly property Process scanProcess: Process {
        command: [root.script, "list-wallpapers"]
        running: true
        onExited:{root.scanning=false;if(root.scanAgain){root.scanAgain=false;Qt.callLater(root.scan)}}
        stdout: StdioCollector {
            onStreamFinished: {
                const list = root.parseJson(text)
                if (Array.isArray(list) && JSON.stringify(list) !== JSON.stringify(root.wallpapers))
                    root.wallpapers = list
            }
        }
    }

    // Posters are made on the first listing, so this one can take a second.
    readonly property Process animatedProcess: Process {
        command: [root.script, "list-animated"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const list = root.parseJson(text)
                if (Array.isArray(list) && JSON.stringify(list) !== JSON.stringify(root.animated))
                    root.animated = list
            }
        }
    }

    readonly property Process currentProcess: Process {
        command: [root.script, "get-state"]
        running: true
        onExited: Qt.callLater(root.startNextWallpaper)
        stdout: StdioCollector {
            onStreamFinished: {
                const state = root.parseJson(text)
                // An older readback must not undo the user's newer selection.
                if (state && root.pendingWallpaper === "") {
                    if (state.currentWallpaper)
                        root.currentWallpaper = state.currentWallpaper
                    root.currentMotion = state.currentMotion ?? ""
                    if (root.readbackPending) {
                        root.applied(root.currentWallpaper)
                        root.pendingLoginWallpaper = root.currentWallpaper
                        Qt.callLater(root.startLoginSync)
                    }
                }
                if (state)
                    root.wallpaperStateLoaded = true
                if (root.readbackPending) {
                    root.readbackPending = false
                    root.applyingWallpaper = false
                    root.asked = ""
                }
                // stdout and process exit may arrive in either order. Both
                // schedule the guarded pump, so the last choice always runs.
                Qt.callLater(root.startNextWallpaper)
            }
        }
    }

    // Keep one command in flight and coalesce rapid clicks to the latest
    // pending choice. Readback belongs to that command, not a later click.
    property string asked: ""
    property string pendingWallpaper: ""
    property bool applyingWallpaper: false
    property bool readbackPending: false
    property string pendingLoginWallpaper: ""

    // Full-resolution greeter conversion is independent of desktop painting.
    // Keep it serial too, retaining only the latest pending login image.
    readonly property Process loginSyncProcess: Process {
        onExited: Qt.callLater(root.startLoginSync)
    }

    function startLoginSync(): void {
        if (root.pickerClosing || root.loginSyncProcess.running || root.pendingLoginWallpaper === "")
            return
        const path = root.pendingLoginWallpaper
        root.pendingLoginWallpaper = ""
        root.loginSyncProcess.command = [root.script, "sync-login-wallpaper", path]
        root.loginSyncProcess.running = true
    }

    signal wallpaperVisible(string path)
    readonly property Process applyProcess: Process {
        stdout: SplitParser {
            onRead: data => {
                if(data.trim() === "wallpaper-visible" && root.pendingWallpaper === "")
                    root.wallpaperVisible(root.asked)
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("Could not apply wallpaper:", root.asked)
                if (root.pendingWallpaper === "")
                    OsdService.requested("󰀦", "Could not apply wallpaper", -1)
            }
            if(exitCode===0&&!root.isMotion(root.asked)){
                const path=root.asked
                if(root.pendingWallpaper===""){
                    root.currentWallpaper=path;root.currentMotion=""
                    root.applied(path)
                    root.pendingLoginWallpaper=path
                    Qt.callLater(root.startLoginSync)
                }
                root.applyingWallpaper=false;root.asked=""
                Qt.callLater(root.startNextWallpaper)
                return
            }
            root.readbackPending = true
            root.currentProcess.running = true
        }
    }

    // ── RESTORE AT LOGIN ────────────────────────────────────────────────────
    //
    // awww's own cache stores the resolved path and breaks if the file moves,
    // so restore from the shell's record, which points at the copy in the
    // data directory. The script only paints outputs that show nothing, so a
    // shell restart does not repaint; it exits 3 while the daemon is still
    // starting (quickshell is launched first), hence the retry.
    readonly property Process restoreProcess: Process {
        command: [root.script, "restore"]
        running: true
        onExited: exitCode => {
            if (exitCode === 3 && restoreRetry.tries < 8) {
                restoreRetry.tries += 1
                restoreRetry.restart()
            }
        }
    }

    readonly property Timer restoreRetry: Timer {
        property int tries: 0
        interval: 1500
        onTriggered: root.restoreProcess.running = true
    }

    // ── HOTPLUG ─────────────────────────────────────────────────────────────
    //
    // awww does not paint outputs added after the wallpaper was set. The
    // restore above only touches empty outputs, so rerun it.
    readonly property Connections hotplug: Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name === "monitoradded" || event.name === "monitoraddedv2")
                root.arriving.restart()
        }
    }

    // One hotplug emits several events, and awww needs a moment to see the
    // new output.
    readonly property Timer arriving: Timer {
        interval: 700
        onTriggered: {
            root.restoreRetry.tries = 0
            root.restoreProcess.running = true
        }
    }

    function parseJson(text: string): var {
        if (!text || text.trim() === "")
            return null
        try {
            return JSON.parse(text)
        } catch (error) {
            console.warn("Cannot parse the wallpaper list:", error)
            return null
        }
    }

    function scan(): void {
        if(root.scanProcess.running){root.scanAgain=true;return}
        root.scanning = true
        root.scanProcess.running = true
        root.animatedProcess.running = true
    }

    // ── TRANSITIONS ─────────────────────────────────────────────────────────
    //
    // awww transition types under the shell's labels. `random` picks from
    // these rows rather than using awww's own, which can pick `none`.
    readonly property var transitions: [
        { id: "fade",   label: "Fade",   type: "fade" },
        { id: "wipe",   label: "Wipe",   type: "wipe" },
        { id: "wave",   label: "Wave",   type: "wave" },
        { id: "circle", label: "Circle", type: "center" },
        { id: "left", label: "From left", type: "left" },
        { id: "right", label: "From right", type: "right" },
        { id: "top", label: "From top", type: "top" },
        { id: "bottom", label: "From bottom", type: "bottom" },
        { id: "grow", label: "Corner bloom", type: "grow" },
        { id: "any", label: "Grow from random point", type: "any" },
        { id: "outer",  label: "Outer",  type: "outer" },
        { id: "none",   label: "None",   type: "none" },
        { id: "random", label: "Random", type: "" }
    ]

    function transitionType(id: string): string {
        if (id === "random") {
            const allowed = SettingsService.wallpaperRandomTransitions
            const pool = root.transitions.filter(entry => entry.type !== "" && entry.type !== "none"
                && (allowed === null || allowed.includes(entry.id)))
            return pool.length ? pool[Math.floor(Math.random() * pool.length)].type : "fade"
        }
        const entry = root.transitions.find(entry => entry.id === id)
        return entry && entry.type !== "" ? entry.type : "wipe"
    }

    function apply(path: string, adaptive = true): void {
        if (!path)
            return
        if(SettingsService.wallpaperCloseAfterApply)root.pickerCloseRequested()
        root.wallpaperRequested(path)
        if(adaptive)root.adaptiveWallpaperRequested(path)
        if (root.isMotion(path)) {
            root.currentMotion = path
        } else {
            root.currentMotion = ""
            root.currentWallpaper = path
        }
        root.pendingWallpaper = path
        Qt.callLater(root.startNextWallpaper)
    }

    function startNextWallpaper(): void {
        if (root.applyingWallpaper || root.applyProcess.running
                || root.currentProcess.running || root.pendingWallpaper === "")
            return
        const path = root.pendingWallpaper
        root.pendingWallpaper = ""
        root.asked = path
        root.applyingWallpaper = true
        root.applyProcess.command = [root.script, "set-wallpaper", path,
                                     root.transitionType(SettingsService.wallpaperTransition), "--defer-login",
                                     "--duration-ms",String(SettingsService.wallpaperTransitionDuration)]
        root.applyProcess.running = true
    }
}
