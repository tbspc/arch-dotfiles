// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   A P P E A R A N C E   S E C T I O N                                    │
// │   appearance · palette, windows, fonts and motion                        │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts

import "../theme"
import "../services"
import "../components"

// The wallpaper and its palette, the terminal, type and the shell's motion.
// What Hyprland does to windows is `WindowsSection`.
SettingsSection {
    id: root

    // The visible part; set by `SettingsPanel`.
    property string tab: ""

    signal panelRequested(string panel)

    Component.onCompleted: FontService.load()
    ColourThemeSaver {visible:root.tab==="theme"}
    Loader {active:root.tab==="editor";Layout.fillWidth:true;sourceComponent:Component {ColourThemeSaver {editing:true}}}
    SettingGroup {visible:root.tab==="theme";title:Tr.t("Nautilus");
        SettingRow {
            label:Tr.t("Open Files as")
            reading:Tr.t("Applies to open and newly opened Files windows")
            SegmentedControl {
                options:[{id:"tiled",label:Tr.t("Window management")},{id:"floating",label:Tr.t("Floating")}]
                current:SettingsService.nautilusWindowMode
                onSelected:id=>SettingsService.set("nautilusWindowMode",id)
            }
        }
SettingRow {label:Tr.t("Icon preset");reading:Tr.t("Choose coloured folders, outlines, or the compact reference’s filled monochrome icons.");SegmentedControl {options:[{id:"filled",label:Tr.t("Coloured")},{id:"outline",label:Tr.t("Outline")},{id:"reference",label:Tr.t("Monochrome (Default)")}];current:SettingsService.nautilusIconStyle;onSelected:id=>SettingsService.set("nautilusIconStyle",id)}}}

    AppBlurControls {visible:root.tab==="theme";app:"nautilus"}

    ThemeWallpaperCollection {visible:root.tab==="wallpaper"||root.tab==="theme"}

    // ── WALLPAPER ───────────────────────────────────────────────────────────

    ColumnLayout {
        Layout.fillWidth: true
        spacing: root.spacing
        visible: root.tab === "wallpaper" || root.tab === "theme"

        // Theme and wallpaper are chosen in the island's appearance panel;
        // this row only opens it.
        SettingGroup {
            visible: root.tab === "theme"
            title: Tr.t("Theme")
            note: Tr.t("The palette follows the wallpaper, and both are chosen in the island.")
            hint: Tr.t("This opens the island's appearance panel, where wallpapers and palettes are chosen together.")

            SettingRow {
                label: Tr.t("Theme and wallpaper")
                reading: Theme.activeName

                PillButton {
                    text: Tr.t("Open")
                    icon: "󰏘"
                    active: true
                    implicitWidth: 92
                    implicitHeight: 30
                    onClicked: root.panelRequested("appearance")
                }
            }
        }

        SettingGroup {
            visible: root.tab === "wallpaper"
            title:Tr.t("Wallpaper switcher")
            SettingRow {
                label:Tr.t("Close after applying wallpaper")
                reading:Tr.t("Close after Enter or a wallpaper selection")
                ToggleSwitch {
                    checked:SettingsService.wallpaperCloseAfterApply
                    onToggled:checked=>SettingsService.set("wallpaperCloseAfterApply",checked)
                }
            }
            SettingRow {
                label:Tr.t("Apply bar colours when wallpaper appears")
                reading:Tr.t("Update as soon as the wallpaper is displayed, with no added delay")
                ToggleSwitch {
                    checked:SettingsService.wallpaperColorsAfterTransition
                    onToggled:checked=>SettingsService.set("wallpaperColorsAfterTransition",checked)
                }
            }

        }

        // Each tile loops its awww transition in miniature.
        SettingGroup {
            visible: root.tab === "wallpaper"
            title: Tr.t("Transition")
            note: Tr.t("How the next wallpaper arrives over the last one.")
            hint: Tr.t("Random picks one of the effects above each time a wallpaper is applied.")

            SettingSlider {
                label:Tr.t("Transition duration")
                from:0;to:3000;unit:" ms"
                value:SettingsService.wallpaperTransitionDuration
                onMoved:value=>SettingsService.set("wallpaperTransitionDuration",Math.round(value))
            }
            SettingTiles {
                label: Tr.t("Effect")

                Repeater {
                    model: WallpaperService.transitions.filter(e => !["left","right","top","bottom","grow","any"].includes(e.id))

                    PreviewTile {
                        id: transitionTile

                        required property var modelData

                        stageHeight: 52
                        caption: Tr.t(transitionTile.modelData.label)
                        selected: SettingsService.wallpaperTransition === transitionTile.modelData.id
                        onPicked: SettingsService.set("wallpaperTransition", transitionTile.modelData.id)

                        WallpaperTransitionPreview {
                            anchors.centerIn: parent
                            effect: transitionTile.modelData.id
                        }
                    }
                }
            }

            SettingTiles {
                label: Tr.t("More transitions")

                Repeater {
                    model: WallpaperService.transitions.filter(e => ["left","right","top","bottom","grow","any"].includes(e.id))

                    PreviewTile {
                        id: transitionTile

                        required property var modelData

                        stageHeight: 52
                        caption: Tr.t(transitionTile.modelData.label)
                        selected: SettingsService.wallpaperTransition === transitionTile.modelData.id
                        onPicked: SettingsService.set("wallpaperTransition", transitionTile.modelData.id)

                        WallpaperTransitionPreview {
                            anchors.centerIn: parent
                            effect: transitionTile.modelData.id
                        }
                    }
                }
            }
        }
    }

    SettingGroup {
        visible: root.tab === "wallpaper"
        id: randomTransitionsGroup
        title: Tr.t("Random transition selection")
        note: Tr.t("Choose the effects used by Random. Keep at least one enabled.")
        readonly property var choices: WallpaperService.transitions.filter(e => e.type !== "" && e.type !== "none")
        readonly property var selected: SettingsService.wallpaperRandomTransitions === null
            ? choices.map(e => e.id) : SettingsService.wallpaperRandomTransitions
        Repeater {
            model: randomTransitionsGroup.choices
            SettingRow {
                required property var modelData
                label: Tr.t(modelData.label)
                ToggleSwitch {
                    checked: SettingsService.wallpaperRandomTransitions === null || SettingsService.wallpaperRandomTransitions.includes(modelData.id)
                    onToggled: checked => {
                        const all = WallpaperService.transitions.filter(e => e.type !== "" && e.type !== "none").map(e => e.id)
                        const selected = SettingsService.wallpaperRandomTransitions === null ? all : SettingsService.wallpaperRandomTransitions.slice()
                        const next = checked ? Array.from(new Set(selected.concat([modelData.id]))) : selected.filter(id => id !== modelData.id)
                        if (next.length) SettingsService.set("wallpaperRandomTransitions", next)
                    }
                    enabled: !checked || (SettingsService.wallpaperRandomTransitions === null
                        ? WallpaperService.transitions.length - 2 : SettingsService.wallpaperRandomTransitions.length) > 1
                }
            }
        }
    }

    // ── TERMINAL ────────────────────────────────────────────────────────────

    ColumnLayout {
        Layout.fillWidth: true
        spacing: root.spacing
        visible: root.tab === "terminal"

        SettingGroup {
            title: Tr.t("Look")
            note: Tr.t("What kitty's window is made of.")
            hint: Tr.t("Classic is solid black, Glass the accent-tinted ground over a blur of the wallpaper, and Liquid a clear frosted pane. Its typeface is the monospace one, under Type.")

            GroundRow {
                key: "terminalGround"
            }
        }

        Loader {
            active: root.tab === "terminal" && SettingsService.terminalGround === "blur"
            Layout.fillWidth: true
            sourceComponent: Component {TerminalBlurControls {}}
        }

        // The tiles play the generated greeting scenes in the current palette.
        SettingGroup {
            title: Tr.t("Greeting")
            note: Tr.t("The animation shown beside fastfetch when you run fa.")
            hint: Tr.t("Four pixel-art scenes, redrawn in the current palette whenever it changes. Random picks a new one on every run, and fa with a scene name (fa koi) plays that one.")

            SettingTiles {
                label: Tr.t("Scene")

                Repeater {
                    model: ThemeService.greetings

                    PreviewTile {
                        id: greetingTile

                        required property var modelData

                        stageHeight: 124
                        caption: Tr.t(greetingTile.modelData.label)
                        selected: SettingsService.greeting === greetingTile.modelData.id
                        onPicked: SettingsService.set("greeting", greetingTile.modelData.id)

                        GreetingPreview {
                            anchors.centerIn: parent
                            scene: greetingTile.modelData.id
                            version: ThemeService.greetingStamp
                        }
                    }
                }
            }
        }
    }

    // ── TYPE ────────────────────────────────────────────────────────────────
    //
    // Families come from fontconfig: Qt silently substitutes a family that is
    // not installed, so a typed name could look applied when it is not.

    ColumnLayout {
        Layout.fillWidth: true
        spacing: root.spacing
        visible: root.tab === "type"

        SettingGroup {
            title: Tr.t("Interface")
            note: Tr.t("Everything Quickshell draws.")

            SettingBlock {
                padding: 6

                FontPicker {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 132
                    families: FontService.sans
                    current: SettingsService.fontFamily
                    sample: "The quick brown fox 0123"
                    onPicked: family => SettingsService.set("fontFamily", family)
                }
            }
        }

        SettingGroup {
            title: Tr.t("Monospace")
            note: Tr.t("The bar's glyphs and readings, and the terminal.")
            hint: Tr.t("kitty is given the same family, so the terminal and the shell always match. It must be a Nerd Font, or the bar's icons show as empty boxes.")

            SettingBlock {
                padding: 6

                FontPicker {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 132
                    families: FontService.mono
                    current: SettingsService.fontMono
                    sample: "il1 O0 {} => 0123"
                    warning: Tr.t("Icons need a Nerd Font patched family.")
                    onPicked: family => SettingsService.set("fontMono", family)
                }
            }
        }
    }

    // ── MOTION ──────────────────────────────────────────────────────────────
    //
    // The shell's own pace; the windows' animation is Hyprland's, on the
    // Windows page, and neither can use the other's curves.

    ColumnLayout {
        Layout.fillWidth: true
        spacing: root.spacing
        visible: root.tab === "motion"

        SettingGroup {
            title: Tr.t("Game mode")
            note: Tr.t("Everything still, for a game or a slow machine.")
            hint: Tr.t("Stops the shell's animations, the spectrum and the pet, makes the island, the dock and the widgets solid without shadows, and turns off Hyprland's animations, blur, shadow and glass. The settings below are kept and come back when it is turned off.")

            SettingRow {
                label: Tr.t("Game mode")
                reading: ShortcutService.current("Shell · Turn game mode on or off")

                ToggleSwitch {
                    checked: SettingsService.gameMode
                    onToggled: checked => SettingsService.set("gameMode", checked)
                }
            }
        }

        SettingGroup {
            title: Tr.t("The shell")
            note: Tr.t("The island, its panels, the chips — everything Qt draws.")

            // Grouped rows keep every live preview large enough to read.
            Repeater {
                model: [
                    { label: "Pace", presets: Theme.motionPresets.slice(0, 4) },
                    { label: "Bounce styles", presets: Theme.motionPresets.slice(4, 7) },
                    { label: "Fade styles", presets: Theme.motionPresets.slice(7) }
                ]

                SettingTiles {
                    id: motionRow
                    required property var modelData
                    required property int index

                    label: Tr.t(motionRow.modelData.label)
                    reading: motionRow.index === 0 && !Theme.motionPresets.some(
                        row => row.scale === SettingsService.motionScale
                            && row.curve === SettingsService.motionCurve) ? Tr.t("Custom") : ""

                    Repeater {
                        model: motionRow.modelData.presets

                        PreviewTile {
                            id: shellTile
                            required property var modelData

                            stageHeight: motionRow.index === 1 ? 72 : 60
                            caption: Tr.t(shellTile.modelData.label)
                            selected: SettingsService.motionScale === shellTile.modelData.scale
                                && SettingsService.motionCurve === shellTile.modelData.curve
                            onPicked: {
                                SettingsService.set("motionScale", shellTile.modelData.scale)
                                SettingsService.set("motionCurve", shellTile.modelData.curve)
                            }

                            IslandMotionPreview {
                                anchors.centerIn: parent
                                preset: shellTile.modelData
                            }
                        }
                    }
                }
            }
        }
    }
}
