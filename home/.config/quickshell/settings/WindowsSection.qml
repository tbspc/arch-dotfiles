// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   W I N D O W S   S E C T I O N                                          │
// │   windows · layout, shape, depth and animation                           │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts

import "../theme"
import "../services"
import "../components"

// Everything Hyprland does to a window: how windows are laid out and shaped,
// what shows through them, and how they move.
//
// These values are stored in the shell's settings and pushed to Hyprland at
// login and after every reload. `hypr/modules/look.lua` holds the defaults
// and is never written.
SettingsSection {
    id: root

    // Unused: this page has no parts, but `SettingsPanel` sets it on all pages.
    property string tab: ""

    Component.onCompleted: {
        CompositorService.load()
        CompositorService.loadGlass()
    }

    // The stored value first, the compositor's second: `remember` stores on
    // every drag step while the push to Hyprland is coalesced, so reading the
    // compositor back would lag the slider.
    function live(option: string, fallback: real): real {
        const kept = SettingsService.compositor
        if (kept && kept[option] !== undefined)
            return Number(kept[option])
        return Number(CompositorService.value(option, fallback))
    }

    readonly property bool blurOn: {
        const kept = SettingsService.compositor
        const raw = kept && kept["decoration:blur:enabled"] !== undefined
            ? kept["decoration:blur:enabled"]
            : CompositorService.value("decoration:blur:enabled", true)
        return String(raw) === "true" || raw === true || raw === 1
    }

    SettingGroup {
        visible: root.tab === "layout"
        title: Tr.t("Shape")
        note: Tr.t("How Hyprland draws every window, this one included.")
        hint: Tr.t("Dwindle splits the space each new window lands in, Master keeps one large window beside a stack, and Scrolling lays windows in a row wider than the screen. The preview below is live and at full size. The border stays at zero because gaps and rounding already separate windows; the inner gap applies to each side of a window, so two windows sit twice that apart.")

        SettingBlock {
            WindowsPreview {
                Layout.fillWidth: true
                rounding: root.live("decoration:rounding", 22)
                borderWidth: root.live("general:border_size", 0)
                gapsIn: root.live("general:gaps_in", 7)
                gapsOut: root.live("general:gaps_out", 18)
                inactiveOpacity: root.live("decoration:inactive_opacity", 1)
                blur: root.blurOn ? root.live("decoration:blur:size", 6) : 0
                glassed: SettingsService.windowGlass && CompositorService.glassAvailable
                lifted: SettingsService.windowShadow
                wallpaper: WallpaperService.currentWallpaper
            }
        }

        SettingRow {
            label: Tr.t("Layout")

            SegmentedControl {
                options: CompositorService.windowLayouts.map(
                    entry => ({ id: entry.id, label: Tr.t(entry.label) }))
                current: CompositorService.windowLayout
                onSelected: id => CompositorService.remember("general:layout", id)
            }
        }

        SettingSlider {
            label: Tr.t("Window rounding")
            value: CompositorService.value("decoration:rounding", 22)
            from: 0
            to: 30
            unit: " px"
            onMoved: value => CompositorService.remember("decoration:rounding", Math.round(value))
        }

        SettingSlider {
            label: Tr.t("Border width")
            value: CompositorService.value("general:border_size", 0)
            from: 0
            to: 6
            reading: CompositorService.value("general:border_size", 0) === 0
                ? Tr.t("None") : `${CompositorService.value("general:border_size", 0)} px`
            onMoved: value => CompositorService.remember("general:border_size", Math.round(value))
        }

        SettingSlider {
            label: Tr.t("Inner gap")
            value: CompositorService.value("general:gaps_in", 7)
            from: 0
            to: 20
            unit: " px"
            onMoved: value => CompositorService.remember("general:gaps_in", Math.round(value))
        }

        SettingSlider {
            label: Tr.t("Outer gap")
            value: CompositorService.value("general:gaps_out", 18)
            from: 0
            to: 40
            unit: " px"
            onMoved: value => CompositorService.remember("general:gaps_out", Math.round(value))
        }
    }

    SettingGroup {
        visible: root.tab === "effects"
        title: Tr.t("Depth")
        note: Tr.t("What shows through a window, and what lifts it off the wallpaper.")
        hint: Tr.t("Inactive opacity fades the windows without focus. Blur shows behind anything translucent, such as the terminal. Refraction (a Hyprland plugin, tuned in look.lua) frosts and bends what is behind a window, like wet glass.")

        SettingSlider {
            label: Tr.t("Active opacity")
            value: Math.round(CompositorService.value("decoration:active_opacity", 1)*100)
            from: 30; to: 100; unit: "%"
            onMoved: value => CompositorService.remember("decoration:active_opacity", (Math.round(value)/100).toFixed(2))
        }
        SettingSlider {
            label: Tr.t("Maximized window gap below bar")
            value: SettingsService.maximizedBarGap
            from: 0; to: 60; unit: " px"
            onMoved: value => SettingsService.set("maximizedBarGap", Math.round(value))
        }
        SettingSlider {
            label: Tr.t("Inactive opacity")
            value: Math.round(CompositorService.value("decoration:inactive_opacity", 1) * 100)
            from: 60
            to: 100
            unit: "%"
            onMoved: value => CompositorService.remember(
                "decoration:inactive_opacity", (Math.round(value) / 100).toFixed(2))
        }

        SettingRow {
            label:Tr.t("Window blur")
            reading:Tr.t("Enable or disable blur without changing window opacity.")
            ToggleSwitch {checked:root.blurOn;onToggled:checked=>CompositorService.remember("decoration:blur:enabled",checked?"true":"false")}
        }
        SettingSlider {
            label: Tr.t("Blur strength")
            value: CompositorService.value("decoration:blur:enabled", 0)
                ? CompositorService.value("decoration:blur:size", 4) : 0
            from: 0
            to: 12
            reading: {
                const on = CompositorService.value("decoration:blur:enabled", 0)
                const size = CompositorService.value("decoration:blur:size", 4)
                return on ? `${Tr.t("size")} ${size}` : Tr.t("Off")
            }
            onMoved: value => {
                const size = Math.round(value)
                CompositorService.remember("decoration:blur:enabled", size === 0 ? "false" : "true")
                if (size > 0)
                    CompositorService.remember("decoration:blur:size", size)
            }
        }

        // Locked, with the reason, when the hyprglass plugin is not loaded.
        SettingRow {
            label: Tr.t("Refraction")
            locked: !CompositorService.glassAvailable
            reason: Tr.t("Needs the refraction plugin — run ./setup plugins")

            ToggleSwitch {
                checked: SettingsService.windowGlass
                onToggled: checked => SettingsService.set("windowGlass", checked)
            }
        }

        SettingRow {
            label: Tr.t("Shadow")
            reading: SettingsService.windowShadow
                ? Tr.t("Lifted off the wallpaper") : Tr.t("Flat")

            ToggleSwitch {
                checked: SettingsService.windowShadow
                onToggled: checked => SettingsService.set("windowShadow", checked)
            }
        }

        SettingSlider {
            label: Tr.t("Shadow range")
            value: SettingsService.windowShadowRange
            from: 0
            to: 60
            unit: " px"
            locked: !SettingsService.windowShadow
            reason: Tr.t("Enable the shadow to adjust it")
            onMoved: value => SettingsService.set("windowShadowRange", Math.round(value))
        }

        SettingSlider {label:Tr.t("Shadow sharpness");from:1;to:4;value:SettingsService.windowShadowSharpness;locked:!SettingsService.windowShadow;onMoved:value=>SettingsService.set("windowShadowSharpness",Math.round(value))}
        SettingSlider {label:Tr.t("Shadow horizontal offset");from:-40;to:40;unit:" px";value:SettingsService.windowShadowOffsetX;locked:!SettingsService.windowShadow;onMoved:value=>SettingsService.set("windowShadowOffsetX",Math.round(value))}
        SettingSlider {label:Tr.t("Shadow vertical offset");from:-40;to:40;unit:" px";value:SettingsService.windowShadowOffsetY;locked:!SettingsService.windowShadow;onMoved:value=>SettingsService.set("windowShadowOffsetY",Math.round(value))}
        SettingRow {label:Tr.t("Use theme accent for shadow");ToggleSwitch {checked:SettingsService.windowShadowUseAccent;onToggled:checked=>SettingsService.set("windowShadowUseAccent",checked)}}
        SettingSlider {
            label: Tr.t("Shadow intensity")
            value: SettingsService.windowShadowIntensity
            from: 0
            to: 100
            unit: "%"
            locked: !SettingsService.windowShadow
            reason: Tr.t("Enable the shadow to adjust it")
            onMoved: value => SettingsService.set("windowShadowIntensity", Math.round(value))
        }
    }

    // The hint describes every preset, built from `Motion.presets`.
    SettingGroup {
        visible: root.tab === "motion"
        title: Tr.t("Animation")
        note: Tr.t("How Hyprland animates windows. Reapplied after every reload.")
        hint: Motion.presets.map(
            entry => `${Tr.t(entry.label)} — ${Tr.t(entry.note)}`).join(" ")

        Repeater {
            model: [
                { label: "Original presets", entries: Motion.presets.filter(entry => !entry.group) },
                { label: "Calm and spring", entries: Motion.presets.filter(entry => entry.group === "calm") },
                { label: "Fades", entries: Motion.presets.filter(entry => entry.group === "fade") }
            ]

            SettingTiles {
                id: presetRow
                required property var modelData
                label: Tr.t(presetRow.modelData.label)

                Repeater {
                    model: presetRow.modelData.entries

                    PreviewTile {
                        id: tile
                        required property var modelData

                        stageHeight: 52
                        caption: Tr.t(tile.modelData.label)
                        selected: SettingsService.animationPreset === tile.modelData.id
                        onPicked: SettingsService.set("animationPreset", tile.modelData.id)

                        MotionPreview {
                            anchors.centerIn: parent
                            width: parent.width - 22
                            preset: tile.modelData
                        }
                    }
                }
            }
        }
    }
}
