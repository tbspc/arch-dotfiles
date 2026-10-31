// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   B A R   S E C T I O N                                                  │
// │   bar · island, layout, workspaces and notifications                     │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import Quickshell

import "../theme"
import "../services"
import "../components"

// Three parts: how the bar is drawn, what it carries (`ModulesPart`), and the
// workspaces its strip shows. What the island shows is `IslandSection`.
SettingsSection {
    id: root

    // The visible part; set by `SettingsPanel`.
    property string tab: ""

    // ── STYLE ───────────────────────────────────────────────────────────────

    ColumnLayout {
        Layout.fillWidth: true
        spacing: root.spacing
        visible: root.tab === "style"

        SettingGroup {
            title: Tr.t("Shape")
            note: Tr.t("How the bar is drawn round the island.")
            hint: Tr.t("The style keeps what is on the bar and only changes how it is drawn: grouped round the island, spread to the two edges, all inside one capsule, or a bezel across the top edge. Rounded corners round every screen, and curve under the bezel's ends.")

            SettingTiles {
                label: Tr.t("Style")
                reading: Tr.t((SettingsService.barStyles.find(
                    entry => entry.id === SettingsService.barStyle) ?? { note: "" }).note)

                Repeater {
                    model: SettingsService.barStyles

                    PreviewTile {
                        id: styleTile

                        required property var modelData

                        caption: Tr.t(styleTile.modelData.label)
                        selected: SettingsService.barStyle === styleTile.modelData.id
                        onPicked: SettingsService.set("barStyle", styleTile.modelData.id)

                        BarPreview {
                            anchors.centerIn: parent
                            attached: SettingsService.islandAttached
                            barStyle: styleTile.modelData.id
                        }
                    }
                }
            }

            SettingRow{visible:SettingsService.surfaceStyle === "classic";label:Tr.t("Black/grey");reading:Tr.t("Solid colour for the bar and all modules");SegmentedControl{options:[{id:"grey",label:Tr.t("Dark grey")},{id:"black",label:Tr.t("Black")}];current:SettingsService.floatingBarSurface;onSelected:id=>SettingsService.set("floatingBarSurface",id)}}
            SettingRow {
                label: Tr.t("Rounded corners")
                reading: SettingsService.screenCorners
                    ? Tr.t("Every screen's corners curve like the windows")
                    : Tr.t("Square, as the panel is")

                ToggleSwitch {
                    checked: SettingsService.screenCorners
                    onToggled: checked => SettingsService.set("screenCorners", checked)
                }
            }

            // Locked in one capsule, where the sides sit on its band.
            SettingRow {
                label: Tr.t("Sides")
                reading: SettingsService.barSides === "bare"
                    ? Tr.t("The icons on the wallpaper")
                    : Tr.t("Each group in a capsule")
                locked: SettingsService.barStyle === "island" || SettingsService.barStyle === "bezel"
                reason: Tr.t("In one island the sides sit on its band")

                SegmentedControl {
                    options: [
                        { id: "capsule", label: Tr.t("In capsules") },
                        { id: "bare", label: Tr.t("On the wallpaper") }
                    ]
                    current: SettingsService.barSides
                    onSelected: id => SettingsService.set("barSides", id)
                }
            }

            SettingRow { label:Tr.t("Auto-hide bar / Island");reading:Tr.t("Move the pointer to the top edge to reveal it.")
                ToggleSwitch {checked:SettingsService.barAutoHide;onToggled:checked=>SettingsService.set("barAutoHide",checked)}
            }
            SettingRow {label:Tr.t("Smart Auto-hide");reading:Tr.t("Hide only when a window overlaps the bar.");locked:!SettingsService.barAutoHide;reason:Tr.t("Enable Auto-hide first")
                ToggleSwitch {checked:SettingsService.barAutoHideSmart;onToggled:value=>SettingsService.set("barAutoHideSmart",value)}
            }
            SettingRow {
                label: Tr.t("On every screen")
                reading: SettingsService.barEverywhere
                    ? Tr.t("One on each, and the one you are on is the live one")
                    : Tr.t("Only on the screen you are on")
                locked: Quickshell.screens.length < 2
                reason: Tr.t("Only one screen is on")

                ToggleSwitch {
                    checked: SettingsService.barEverywhere
                    onToggled: checked => SettingsService.set("barEverywhere", checked)
                }
            }
        }

        SettingGroup {
            title: Tr.t("Scale")
            note: Tr.t("The bar itself is the preview: it repaints over this window as the sliders move.")
            hint: Tr.t("Overall size scales width, height, contents and notch together. Open modules keep their normal size. The top margin is the gap to the screen edge (the island ignores it in notch mode), and the side margin is the inset from the left and right edges.")

            SettingSlider {
                label:Tr.t("Overall bar size")
                value:SettingsService.barScale;from:50;to:150;unit:"%"
                onMoved:value=>SettingsService.set("barScale",Math.round(value))
            }
            SettingSlider {
                label: Tr.t("Bar height")
                value: SettingsService.barHeight
                from: 24
                to: 48
                unit: " px"
                onMoved: value => SettingsService.set("barHeight", Math.round(value))
            }

            SettingSlider {
                label: Tr.t("Top margin")
                value: SettingsService.barMargin
                from: 0
                to: 32
                unit: " px"
                onMoved: value => SettingsService.set("barMargin", Math.round(value))
            }

            SettingSlider {
                label: Tr.t("Side margin")
                value: SettingsService.barSideMargin
                from: 0
                to: 48
                unit: " px"
                onMoved: value => SettingsService.set("barSideMargin", Math.round(value))
            }
        }

        SettingGroup {
            title: Tr.t("Look")
            note: Tr.t("What the bar and the island are made of.")
            hint: Tr.t("Liquid uses clear Hyprglass refraction with no rainbow color separation. Liquid (Old) restores the earlier frosted look. Opacity, wallpaper tint, and edge shine apply to both; refraction and blur tune Liquid.")

            GroundRow {
                key: "surfaceStyle"
            }

            SettingSlider {
                visible: SettingsService.surfaceStyle === "liquid"
                label: Tr.t("Glass opacity")
                value: SettingsService.liquidOpacity
                from: 22
                to: 75
                unit: "%"
                onMoved: value => SettingsService.set("liquidOpacity", Math.round(value))
            }

            SettingSlider {
                visible: SettingsService.surfaceStyle === "liquid-old"
                label: Tr.t("Old Liquid opacity")
                value: SettingsService.liquidOldOpacity
                from: 20
                to: 80
                unit: "%"
                onMoved: value => SettingsService.set("liquidOldOpacity", Math.round(value))
            }

            SettingSlider {
                visible: Theme.isLiquid(SettingsService.surfaceStyle)
                label: Tr.t("Wallpaper tint")
                value: SettingsService.liquidTint
                from: 0
                to: 100
                unit: "%"
                onMoved: value => SettingsService.set("liquidTint", Math.round(value))
            }

            SettingSlider {
                visible: SettingsService.surfaceStyle === "liquid"
                label: Tr.t("Refraction")
                value: SettingsService.liquidRefraction
                from: 0
                to: 100
                unit: "%"
                onMoved: value => SettingsService.set("liquidRefraction", Math.round(value))
            }

            SettingSlider {
                visible: SettingsService.surfaceStyle === "liquid"
                label: Tr.t("Blur")
                value: SettingsService.liquidBlur
                from: 0
                to: 100
                unit: "%"
                onMoved: value => SettingsService.set("liquidBlur", Math.round(value))
            }

            SettingSlider {
                visible: Theme.isLiquid(SettingsService.surfaceStyle)
                label: Tr.t("Edge shine")
                value: SettingsService.liquidShine
                from: 20
                to: 100
                unit: "%"
                onMoved: value => SettingsService.set("liquidShine", Math.round(value))
            }

            SettingRow {
                label: Tr.t("Shadow")
                reading: SettingsService.barShadow
                    ? Tr.t("Lifted off the wallpaper") : Tr.t("Flat")

                ToggleSwitch {
                    checked: SettingsService.barShadow
                    onToggled: checked => SettingsService.set("barShadow", checked)
                }
            }

            SettingRow {
                label:Tr.t("Efficient solid shadows in Power Saver")
                reading:Tr.t("Use a lighter renderer for solid island shadows. Range and intensity still apply.")
                ToggleSwitch {checked:SettingsService.powerSaverBarEffects;onToggled:checked=>SettingsService.set("powerSaverBarEffects",checked)}
            }
            SettingSlider {
                label: Tr.t("Shadow range")
                value: SettingsService.barShadowRange
                from: 0
                to: 100
                unit: " px"
                locked: !SettingsService.barShadow
                reason: Tr.t("Enable the shadow to adjust it")
                onMoved: value => SettingsService.set("barShadowRange", Math.round(value))
            }

            SettingSlider {label:Tr.t("Shadow sharpness");from:1;to:6;value:SettingsService.barShadowSharpness;locked:!SettingsService.barShadow;onMoved:value=>SettingsService.set("barShadowSharpness",Math.round(value))}
            SettingSlider {label:Tr.t("Shadow horizontal offset");from:-100;to:100;unit:" px";value:SettingsService.barShadowOffsetX;locked:!SettingsService.barShadow;onMoved:value=>SettingsService.set("barShadowOffsetX",Math.round(value))}
            SettingSlider {label:Tr.t("Shadow vertical offset");from:-100;to:100;unit:" px";value:SettingsService.barShadowOffsetY;locked:!SettingsService.barShadow;onMoved:value=>SettingsService.set("barShadowOffsetY",Math.round(value))}
            SettingRow {label:Tr.t("Use theme accent for shadow");ToggleSwitch {checked:SettingsService.barShadowUseAccent;onToggled:checked=>SettingsService.set("barShadowUseAccent",checked)}}
            SettingSlider {
                label: Tr.t("Shadow intensity")
                value: SettingsService.barShadowIntensity
                from: 0
                to: 200
                unit: "%"
                locked: !SettingsService.barShadow
                reason: Tr.t("Enable the shadow to adjust it")
                onMoved: value => SettingsService.set("barShadowIntensity", Math.round(value))
            }
        }
    }

    // ── WORKSPACES ──────────────────────────────────────────────────────────

    SettingGroup {
        visible: root.tab === "workspaces"
        title: Tr.t("Workspaces")
        SettingRow {
            label: Tr.t("Repeat shortcut returns to previous workspace")
            reading: Tr.t("Off: pressing the active workspace number stays on it")
            ToggleSwitch {
                checked: SettingsService.workspaceBackAndForth
                onToggled: checked => SettingsService.set("workspaceBackAndForth", checked)
            }
        }
        note: Tr.t("The shown workspaces are always drawn; the rest, up to the available count, appear only while they have windows.")

        SettingBlock {
            WorkspaceStyles {
                Layout.fillWidth: true
            }
        }

        SettingSlider {
            label: Tr.t("Workspaces shown")
            value: HyprlandService.slots
            from: 1
            to: HyprlandService.maximum
            onMoved: value => SettingsService.set("workspaceCount", Math.round(value))
        }

        SettingSlider {
            label: Tr.t("Workspaces available")
            // Per screen, each screen has ten.
            value: HyprlandService.maximum
            from: 4
            to: HyprlandService.perScreen ? 10 : 20
            onMoved: value => {
                const max = Math.round(value)
                SettingsService.set("workspaceMax", max)
                // The ceiling cannot end up below the floor.
                if (SettingsService.workspaceCount > max)
                    SettingsService.set("workspaceCount", max)
            }
        }

        SettingRow {
            label: Tr.t("With more screens")
            reading: HyprlandService.perScreen
                ? Tr.t("Ten for each screen: the main one 1–10, the next 11–20")
                : Tr.t("Every screen shares the same ten")
            locked: Quickshell.screens.length < 2
            reason: Tr.t("Only one screen is on")

            SegmentedControl {
                options: [
                    { id: "shared", label: Tr.t("Shared") },
                    { id: "screen", label: Tr.t("Per screen") }
                ]
                current: SettingsService.workspaceMode
                onSelected: id => SettingsService.set("workspaceMode", id)
            }
        }
    }
    WorkspaceColourSettings {visible:root.tab==="workspaces"}
    WorkspaceBrightnessSettings {visible:root.tab==="workspaces"}
    WorkspaceGlowSettings {visible:root.tab==="workspaces"}
    SettingGroup {
        id: dimensions
        visible: root.tab === "workspaces"
        property string editing: SettingsService.workspaceStyle
        readonly property bool written: ["numbers","roman","kanji","greek"].includes(editing)
        title: Tr.t("Workspace dimensions")
        note: Tr.t("Each style keeps separate width and height values, on the bar and inside Island chips.")
        SettingBlock {
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: SettingsService.workspaceStyles
                    PillButton {
                        required property var modelData
                        text: Tr.t(modelData.label)
                        active: dimensions.editing === modelData.id
                        onClicked: dimensions.editing = modelData.id
                    }
                }
            }
        }
        SettingSlider {
            label: dimensions.written ? Tr.t("Glyph width") : Tr.t("Width")
            value: SettingsService.workspaceSize(dimensions.editing,"width",dimensions.written ? 100 : dimensions.editing === "bars" ? 3 : dimensions.editing === "rings" ? 7 : 6)
            from: dimensions.written ? 50 : 2; to: dimensions.written ? 180 : 24
            unit: dimensions.written ? "%" : " px"
            onMoved: value => SettingsService.setWorkspaceSize(dimensions.editing,"width",Math.round(value))
        }
        SettingSlider {
            label: dimensions.written ? Tr.t("Glyph height") : Tr.t("Height")
            value: SettingsService.workspaceSize(dimensions.editing,"height",dimensions.written ? 11 : dimensions.editing === "bars" ? 14 : dimensions.editing === "rings" ? 7 : 6)
            from: dimensions.written ? 8 : 2; to: 32; unit: " px"
            onMoved: value => SettingsService.setWorkspaceSize(dimensions.editing,"height",Math.round(value))
        }
        SettingSlider {
            visible: dimensions.editing === "dots"
            label: Tr.t("Active dot width")
            value: SettingsService.workspaceSize("dots","activeWidth",22)
            from: 4; to: 60; unit: " px"
            onMoved: value => SettingsService.setWorkspaceSize("dots","activeWidth",Math.round(value))
        }
        SettingSlider {
            label: Tr.t("Space between workspaces")
            value: SettingsService.workspaceSize(dimensions.editing,"spacing",dimensions.written ? 2 : 8)
            from: 0; to: 24; unit: " px"
            onMoved: value => SettingsService.setWorkspaceSize(dimensions.editing,"spacing",Math.round(value))
        }
        SettingSlider {
            label:Tr.t("Inactive width")
            value:SettingsService.workspaceSize(dimensions.editing,"inactiveWidth",SettingsService.workspaceSize(dimensions.editing,"width",dimensions.written?100:dimensions.editing==="bars"?3:dimensions.editing==="rings"?7:6))
            from:dimensions.written?30:1;to:dimensions.written?200:60;unit:dimensions.written?"%":" px"
            onMoved:value=>SettingsService.setWorkspaceSize(dimensions.editing,"inactiveWidth",Math.round(value))
        }
        SettingSlider {
            label:Tr.t("Inactive height")
            value:SettingsService.workspaceSize(dimensions.editing,"inactiveHeight",SettingsService.workspaceSize(dimensions.editing,"height",dimensions.written?11:dimensions.editing==="bars"?14:dimensions.editing==="rings"?7:6)*(dimensions.editing==="bars"?5/14:1))
            from:1;to:48;unit:" px";onMoved:value=>SettingsService.setWorkspaceSize(dimensions.editing,"inactiveHeight",Math.round(value))
        }
        SettingSlider {
            label:Tr.t("Active width")
            value:SettingsService.workspaceSize(dimensions.editing,"activeWidth",SettingsService.workspaceSize(dimensions.editing,"width",dimensions.written?100:dimensions.editing==="bars"?3:dimensions.editing==="rings"?9:22))
            from:dimensions.written?30:1;to:dimensions.written?200:80;unit:dimensions.written?"%":" px"
            onMoved:value=>SettingsService.setWorkspaceSize(dimensions.editing,"activeWidth",Math.round(value))
        }
        SettingSlider {
            label:Tr.t("Active height")
            value:SettingsService.workspaceSize(dimensions.editing,"activeHeight",SettingsService.workspaceSize(dimensions.editing,"height",dimensions.written?11:dimensions.editing==="bars"?14:dimensions.editing==="rings"?9:6))
            from:1;to:48;unit:" px";onMoved:value=>SettingsService.setWorkspaceSize(dimensions.editing,"activeHeight",Math.round(value))
        }

    }

    SettingGroup {
        visible:root.tab==="style" && SettingsService.notched
        title:Tr.t("Notch shape")
        SettingRow {label:Tr.t("2 is circular; higher values create smoother, squarer corners.")}
        SettingSlider {label:Tr.t("Lower corner rounding");from:0;to:60;unit:" px";value:SettingsService.notchCornerRadius<0?Math.min(Theme.capsuleHeight/2,Theme.radiusLarge+4):SettingsService.notchCornerRadius;onMoved:value=>SettingsService.set("notchCornerRadius",Math.round(value))}
SettingSlider {label:Tr.t("Lower corner power");from:1;to:8;stepSize:.1;decimals:1;value:SettingsService.notchRoundingPower;onMoved:value=>SettingsService.set("notchRoundingPower",Math.round(value*10)/10)}
        SettingSlider {label:Tr.t("Screen-to-notch rounding");from:0;to:40;unit:" px";value:SettingsService.notchShoulderRadius;onMoved:value=>SettingsService.set("notchShoulderRadius",Math.round(value))}
SettingSlider {label:Tr.t("Screen-to-notch corner power");from:1;to:8;stepSize:.1;decimals:1;value:SettingsService.notchShoulderRoundingPower;onMoved:value=>SettingsService.set("notchShoulderRoundingPower",Math.round(value*10)/10)}
        SettingSlider {label:Tr.t("Connection position");from:-600;to:600;unit:" px";value:SettingsService.notchOffsetX;onMoved:value=>SettingsService.set("notchOffsetX",Math.round(value))}
    }

}
