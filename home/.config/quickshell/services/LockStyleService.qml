pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

QtObject {
    id: root
    // The live bar supplies its resting silhouette, retained while locked.
    property real barIslandWidth: 0
    property bool bootInstalled: false
    onBootInstalledChanged: if (root.bootInstalled) root.queue()
    property string pending: ""
    property string sent: ""
    property string lastPublished: ""
    property string error: ""

    readonly property var values: {
        const result = {}
        for (const key of SettingsService.profileKeys)
            if (key.startsWith("lock")) result[key] = SettingsService.copy(SettingsService[key])
        result.lockFontFamily = Theme.fontOf(SettingsService.lockFont === "sf-display"
            ? "SF Pro Display, SF Pro, Inter Display, Inter" : SettingsService.lockFont === "mono"
            ? "JetBrainsMono Nerd Font, monospace" : SettingsService.lockFont === "sans"
            ? "Inter, Cantarell, sans-serif" : "SF Pro Rounded, Nunito, Inter Display, Inter")
        result.lockTextColor = SettingsService.lockInk === "accent" ? String(Theme.accent) : "#ffffff"
        result.lockMotion = Theme.motion
        result.lockIslandWidth = (root.barIslandWidth > 0 ? root.barIslandWidth : ModuleService.restWidth)*Theme.barScale
        result.lockIslandHeight = (Theme.capsuleHeight + (SettingsService.notched ? Theme.barTopMargin : 0))*Theme.barScale
        result.lockIslandTop = (SettingsService.notched ? 0 : Math.max(0, Theme.floatingIslandMargin + (SettingsService.islandChipsEnabled ? IslandChipService.get("clock").offsetY : 0)))*Theme.barScale
        result.lockIslandOffset = ((SettingsService.notched?SettingsService.notchOffsetX:0)+(SettingsService.islandChipsEnabled?IslandChipService.get("clock").offsetX:0))*Theme.barScale
        result.lockIslandNotched = SettingsService.notched
        result.user = AccountService.user || Quickshell.env("USER") || ""
        result.displayName = AccountService.name
        result.avatar = AccountService.avatar
        return result
    }
    readonly property string serialized: JSON.stringify(root.values)
    readonly property bool synced: root.lastPublished === root.serialized && root.error === ""
    onSerializedChanged: root.queue()
    function queue(): void {
        if (!SettingsService.arrived || root.serialized === root.lastPublished) return
        root.pending = root.serialized
        debounce.restart()
    }
    function publishNext(): void {
        if (publisher.running || !root.pending) return
        root.sent = root.pending
        root.pending = ""
        root.error = ""
        publisher.command = [Quickshell.shellPath("scripts/publish-lock-style.py"), root.sent]
        publisher.running = true
    }
    readonly property Timer debounce: Timer { interval: 150; onTriggered: root.publishNext() }
    readonly property Process publisher: Process {
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.error = text.trim() }
        onExited: code => {
            if (code === 0) root.lastPublished = root.sent
            else if (!root.error) root.error = "Could not save the boot login style"
            Qt.callLater(root.publishNext)
        }
    }
    readonly property Connections settingsReady: Connections {
        target: SettingsService
        function onArrivedChanged(): void { root.queue() }
    }
    readonly property FileView installed: FileView {
        path: "/usr/share/sddm/themes/impasto/lock-design.version"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.bootInstalled = text().trim() === "1"
        onLoadFailed: root.bootInstalled = false
    }
    Component.onCompleted: root.queue()
}
