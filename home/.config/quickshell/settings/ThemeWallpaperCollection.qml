import QtQuick
import Quickshell
import "../theme"
import "../services"
import "../components"

SettingGroup {
    id:root
    title:Tr.t("Theme wallpaper library")
    note:Tr.t("Adaptive includes every wallpaper. Named themes have their own collections, keep their colours, and restore their last-used wallpaper.")
    readonly property var choices:ThemeService.availableThemes.filter(theme=>theme.id!=="adaptive")
    property string editingTheme:ThemeService.activeId==="adaptive"?"tokyo_night":ThemeService.activeId
    readonly property var assigned:ThemeService.wallpapersForTheme(root.editingTheme)
    readonly property bool manual:(SettingsService.wallpaperThemeLinks[root.editingTheme]||[]).includes(WallpaperService.chosen)
    readonly property bool included:root.assigned.some(entry=>entry.path===WallpaperService.chosen)||(ThemeService.paletteFor(root.editingTheme)?.wallpaper===WallpaperService.chosen)
    readonly property string folder:(Quickshell.env("XDG_DATA_HOME")||Quickshell.env("HOME")+"/.local/share")+"/wallpapers/themes"

    SettingRow {
        label:Tr.t("Wallpaper switcher preset")
        reading:Tr.t("Changes only the wallpaper page. The theme switcher keeps its own design.")
        SegmentedControl {
            options:[{id:"carousel",label:Tr.t("Classic")},{id:"reference",label:Tr.t("Theme Strip")}]
            current:SettingsService.wallpaperPickerDesign
            onSelected:id=>ModulePresetService.wallpaperDesign(id)
        }
    }
    SettingRow {
        label:Tr.t("Start on")
        reading:Tr.t("The first page shown when opening the wallpaper switcher")
        SegmentedControl {
            options:[{id:"wallpaper",label:Tr.t("Wallpaper")},{id:"palette",label:Tr.t("Themes")}]
            current:SettingsService.wallpaperStartPage
            onSelected:id=>SettingsService.set("wallpaperStartPage",id)
        }
    }
    SettingRow {
        label:Tr.t("Filter wallpapers by selected theme")
        reading:Tr.t("Turn off to browse the full library with any theme. Adaptive always shows everything.")
        ToggleSwitch {checked:SettingsService.wallpaperFilterByTheme;onToggled:value=>SettingsService.set("wallpaperFilterByTheme",value)}
    }
    SettingRow {
        label:Tr.t("Manage collection")
        ThemedComboBox {
            model:root.choices;textRole:"name"
            currentIndex:Math.max(0,root.choices.findIndex(theme=>theme.id===root.editingTheme))
            onActivated:index=>{root.editingTheme=root.choices[index].id}
        }
    }
    SettingRow {
        label:Tr.t("Wallpapers in collection")
        reading:root.assigned.length+Tr.t(" images · linked wallpapers and your additions are included")
        PillButton {text:Tr.t("Open folders");onClicked:Qt.openUrlExternally("file://"+root.folder)}
    }
    SettingRow {
        label:Tr.t("Current wallpaper")
        reading:WallpaperService.chosen.split("/").pop()||Tr.t("No wallpaper selected")
        PillButton {
            text:root.manual?Tr.t("Remove from collection"):root.included?Tr.t("Already included"):Tr.t("Add to collection")
            enabled:!!WallpaperService.chosen&&(root.manual||!root.included)
            onClicked:ThemeService.setWallpaperMembership(root.editingTheme,WallpaperService.chosen,!root.manual)
        }
    }
    SettingRow {
        label:Tr.t("Add more wallpapers")
        reading:Tr.t("Put images in wallpapers/themes/")+root.editingTheme+Tr.t("/, or add the current wallpaper above. Collections refresh whenever the switcher opens.")
    }
}
