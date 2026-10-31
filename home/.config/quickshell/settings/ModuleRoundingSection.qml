import QtQuick
import "../theme"
import "../services"
import "../components"
SettingsSection {
    id: root
    readonly property var entries: {
        const result = ModuleService.catalogue.filter(item => item.id !== "clock" && item.width > 0).map(item => ({id:item.id,name:item.name}))
        const extra = [{id:"launcher",name:"App launcher"},{id:"controls",name:"Control Centre"},{id:"summary",name:"Calendar and media"},{id:"appearance",name:"Wallpaper selector"},{id:"palette",name:"Palette selector"},{id:"overview",name:"Workspace overview"},{id:"session",name:"Power menu"},{id:"keys",name:"Keybindings"},{id:"packages",name:"Packages"},{id:"machines",name:"Virtual machines"},{id:"servers",name:"Servers"}]
        for (const item of extra) if (!result.some(row => row.id === item.id)) result.push(item)
        return result.sort((a,b) => a.name.localeCompare(b.name))
    }
    SettingGroup {
        title: Tr.t("Rounding for each module")
        note: Tr.t("Each slider changes only that module's outer panel. Notched panels still meet the screen edge.")
        Repeater {
            model: root.entries
            SettingSlider {
                required property var modelData
                label: Tr.t(modelData.name)
                value: SettingsService.moduleRadius(modelData.id,Theme.radiusLarge)
                from: 0; to: 64; unit: " px"
                onMoved: value => {
                    const next = SettingsService.copy(SettingsService.moduleRounding) || {}
                    next[modelData.id] = Math.round(value)
                    SettingsService.set("moduleRounding",next)
                }
            }
        }
    }
}
