pragma Singleton
import QtQuick
import "../theme"

QtObject {
    id: root
    readonly property var ids: ["media", "workspaces", "internet", "bluetooth", "speaker", "battery"]
    readonly property var names: ({clock: "Clock", media: "Media player", workspaces: "Workspaces", internet: "Internet", bluetooth: "Bluetooth", speaker: "Speaker", battery: "Battery"})
    function get(id: string, source: var): var {
        const c = source || SettingsService
        const prefix = ({workspaces:"Workspaces", internet:"Internet", bluetooth:"Bluetooth", speaker:"Speaker", battery:"Battery"})[id]
        const base = { enabled: id === "clock" || (prefix ? c["island" + prefix] : false),
            side: prefix ? c["island" + prefix + "Position"] : "left", order: root.ids.indexOf(id),
            width: id === "clock" ? c.islandPillWidth + c.islandPaddingLeft + c.islandPaddingRight : id === "workspaces" ? 100 : id === "battery" ? 48 : 36,
            height: id === "clock" ? c.barHeight : 36, iconScale: 100, offsetX: 0, offsetY: 0,
            style: id === "workspaces" || id === "clock" || id === "battery" ? "pill" : "circle",
            surface: "solid", autoHide: id === "media", display: id === "media" ? "artwork" : ["internet","speaker"].includes(id) ? "ring" : id === "battery" ? c.islandBatteryMode : "icon" }
        const config = Object.assign(base, c.islandChipSettings?.[id] || {})
        config.width = Math.max(18, Math.min(520, config.width))
        config.height = Math.max(18, Math.min(80, config.height))
        config.iconScale = Math.max(50, Math.min(180, config.iconScale))
        return config
    }
    function list(side: string, source: var, preview: var): var {
        return root.ids.map(id => ({ id, config: root.get(id, source) }))
            .filter(entry => entry.config.enabled && entry.config.side === side
                && (entry.id !== "media" || preview || !entry.config.autoHide || MediaService.playing))
            .sort((a,b) => a.config.order - b.config.order)
    }
    function set(id: string, key: string, value: var): void {
        const next = SettingsService.copy(SettingsService.islandChipSettings) || {}
        next[id] = Object.assign({}, next[id] || {}, { [key]: value })
        SettingsService.set("islandChipSettings", next)
    }
    readonly property real extraBelow: !SettingsService.islandChipsEnabled ? 0
        : Math.max(0, ...root.ids.filter(id => root.get(id).enabled).map(id => {
            const c = root.get(id); return Math.max(c.offsetY+Math.max(0,c.height-SettingsService.barHeight)/2,8/Math.max(.1,Theme.barScale)+c.height-Theme.barBand)
        }))
}
