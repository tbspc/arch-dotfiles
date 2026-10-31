// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   B A R   R E S E R V E                                                  │
// │   the space the bar keeps · held by the screen, not by the bar           │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import Quickshell.Wayland

import "../theme"
import "../services"

// One strip per screen, a pixel tall and painting nothing, whose only job is
// the exclusive zone. The bars reserve nothing themselves, so a bar replaced
// by another kind never lets the space go: tiled windows hold still while the
// island changes screens.
PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    readonly property bool hasMaximizedWindow: {
        const monitor=HyprlandService.monitors.find(item => item.name===root.screen?.name)
        if (!monitor) return false
        return HyprlandService.clients.some(client => client.monitor===monitor.id
            && client.workspace?.id===HyprlandService.activeOn(root.screen.name) && client.fullscreen===1)
    }
    Component.onCompleted: HyprlandService.loadClients()
    implicitHeight: 1
    color: "transparent"
    // Nothing in zen, so the windows take the band.
    exclusiveZone: SettingsService.barHidden || SettingsService.barAutoHide ? 0 : Math.ceil(Theme.barReserve*Theme.barScale)
        + (root.hasMaximizedWindow ? SettingsService.maximizedBarGap + IslandChipService.extraBelow : 0)

    // Under everything, and deaf.
    WlrLayershell.layer: WlrLayer.Background
    mask: Region {}
}
