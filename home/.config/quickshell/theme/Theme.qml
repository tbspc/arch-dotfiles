// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   T H E M E                                                              │
// │   design tokens · consumed by every component                            │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell

import "../services"

// Design tokens for the whole shell. Components read Theme.<token> and never
// hardcode a colour, so a palette change repaints everything.
QtObject {
    id: root

    // ── ACTIVE THEME ────────────────────────────────────────────────────────

    property string activeId: "adaptive"
    property string activeName: "Adaptive (Wallpaper)"

    // ── ISLAND ──────────────────────────────────────────────────────────────

    // Pure black in every palette: the island is the shell's identity, not a
    // themed surface. What changes is how much of it there is
    // (`SettingsService.surfaceStyle`): solid, or glass — the terminal's own
    // ground, the accent scaled towards black at kitty's opacity, over the
    // compositor's blur, with a lit edge — or liquid, a clear pane of light
    // frosted over the blur, lit harder. `island` stays opaque for what is
    // cut out of it; the island, the capsules and the toasts are painted in
    // `islandGround`, and what sits on them in white washes.
    // Game mode is solid everywhere: no glass to blur behind.
    readonly property string surfaceStyle: SettingsService.gameMode ? "classic" : SettingsService.surfaceStyle
    readonly property bool solid: !root.seeThrough(root.surfaceStyle)
    readonly property bool glass: root.seeThrough(root.surfaceStyle)

    // Both glasses let the screen through; only classic does not.
    function isLiquid(style: string): bool {
        return style === "liquid" || style === "liquid-old" || style === "tahoe"
    }

    function seeThrough(style: string): bool {
        return style === "glass" || root.isLiquid(style)
    }

    readonly property color island: "#000000"
    readonly property color islandGround: root.groundOf(root.surfaceStyle)

    // The terminal's ground: `TERMINAL_TINT` and kitty's `background_opacity`.
    readonly property real terminalTint: 0.22
    readonly property real terminalOpacity: 0.90
    readonly property color terminalGround: Qt.rgba(root.accent.r * root.terminalTint,
        root.accent.g * root.terminalTint, root.accent.b * root.terminalTint, root.terminalOpacity)

    // A restrained blue-white tint for Hyprglass; the wallpaper supplies the
    // material's colors. Keep the old dark frosted ground as a separate preset.
    readonly property color liquidGround: {
        const tint = SettingsService.liquidTint / 100
        const accent = root.accent
        return Qt.rgba(
            0.40 + accent.r * 0.28 * tint,
            0.58 + accent.g * 0.24 * tint,
            0.78 + accent.b * 0.16 * tint,
            Math.min(0.36, 0.10 + SettingsService.liquidOpacity / 100 * 0.25))
    }

    readonly property color liquidOldGround: {
        const tint = SettingsService.liquidTint / 100
        const accent = root.accent
        return Qt.rgba(
            0.012 + accent.r * 0.10 * tint,
            0.025 + accent.g * 0.22 * tint,
            0.055 + accent.b * 0.38 * tint,
            SettingsService.liquidOldOpacity / 100)
    }

    // Any style's ground and rim, for a picture of one that is not chosen.
    function groundOf(style: string): color {
        return style === "tahoe" ? Qt.rgba(0.11,0.14,0.19,0.16+SettingsService.macGlassTint*0.0004)
            : style === "liquid-old" ? root.liquidOldGround
            : style === "liquid" ? root.liquidGround
            : style === "glass" ? root.terminalGround : SettingsService.floatingBarSurface === "grey" ? root.islandSurface : root.island
    }

    // A ground at a fraction of its own opacity: the Background slider's,
    // which thins the glass the way it thins the black.
    function groundAt(style: string, fraction: real): color {
        const ground = root.groundOf(style)
        return Qt.rgba(ground.r, ground.g, ground.b, ground.a * fraction)
    }

    // Liquid's own rim is only a trace: its light is `litRim`, drawn by the
    // sheen from one side.
    function rimOf(style: string): color {
        return style === "tahoe" ? "transparent"
            : style === "liquid-old" ? Qt.rgba(1, 1, 1, 0.08)
            : style === "liquid" ? Qt.rgba(1, 1, 1, 0.16)
            : style === "glass" ? Qt.rgba(1, 1, 1, 0.20) : "#262626"
    }
    readonly property color islandSurface: "#141414"
    readonly property color islandSurfaceHover: "#1f1f1f"
    readonly property color islandBorder: "#262626"

    // The desk's widgets have a ground of their own
    // (`SettingsService.desktopGround`; empty, from an old file, follows).
    readonly property string deskStyle: SettingsService.gameMode ? "classic"
        : SettingsService.desktopGround || root.surfaceStyle
    readonly property bool deskSolid: !root.seeThrough(root.deskStyle)
    readonly property bool deskGlass: root.seeThrough(root.deskStyle)

    // The dock's, the same way (`SettingsService.dockGround`).
    readonly property string dockStyle: SettingsService.gameMode ? "classic"
        : SettingsService.dockGround || root.surfaceStyle
    readonly property bool dockGlass: root.seeThrough(root.dockStyle)

    // The same three on glass: white veils, by style. Only the bar's and the
    // desk's windows are glass, each in its own style (a `glassy` window
    // with a `groundStyle`), and the dock, which asks `dockStyle` directly;
    // everything else — the settings, the lock — stays black, so a part
    // drawn in both asks by its window (`surfaceIn`).
    function veilOf(style: string): color {
        return root.isLiquid(style) ? Qt.rgba(1, 1, 1, 0.07)
            : style === "glass" ? Qt.rgba(1, 1, 1, 0.08) : root.islandSurface
    }

    function veilHoverOf(style: string): color {
        return root.isLiquid(style) ? Qt.rgba(1, 1, 1, 0.13)
            : style === "glass" ? Qt.rgba(1, 1, 1, 0.14) : root.islandSurfaceHover
    }

    function veilLineOf(style: string): color {
        return root.isLiquid(style) ? Qt.rgba(1, 1, 1, 0.18)
            : style === "glass" ? Qt.rgba(1, 1, 1, 0.12) : root.islandBorder
    }

    function colourChannels(value:color):color {return value}
    function hasModuleColour(id:string,role:string):bool {
        const sync=SettingsService.moduleColourSync
        return !!SettingsService.shellColours[id]?.[role] || !!(sync.enabled && sync[role])
    }
    // Resolve the shared palette once per colour change, rather than doing
    // conversion/brightness work independently for every label and icon.
    readonly property color sharedModuleText:root.sharedModuleColour("foreground",root.text)
    readonly property color sharedModuleAccent:root.sharedModuleColour("accent",root.accent)
    readonly property color sharedModuleMuted:root.sharedModuleColour("muted",root.textMuted)
    readonly property color sharedModuleBackground:root.sharedModuleColour("background",root.islandGround)
    function sharedModuleColour(role:string,fallback:color):color {
        const sync=SettingsService.moduleColourSync,value=sync[role]
        if(!sync.enabled || !value)return fallback
        let color=fallback
        if(value==="wallpaper")color=ThemeService.dynamicColors?.accent || root.accent
        else if(value==="accent")color=root.accent
        else if(/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value))color=value
        const ink=root.colourChannels(color)
        if(role==="background")return Qt.rgba(ink.r,ink.g,ink.b,ink.a*Math.max(0,Math.min(100,Number(sync.backgroundOpacity??100)))/100)
        const brightness=Math.max(0,Math.min(150,Number(sync[role+"Brightness"]??100)))/100
        return Qt.rgba(Math.min(1,ink.r*brightness),Math.min(1,ink.g*brightness),Math.min(1,ink.b*brightness),ink.a)
    }
    function moduleColour(id:string,role:string,fallback:color):color {
        const sync=SettingsService.moduleColourSync
        const individual=SettingsService.shellColours[id]?.[role]
        if(sync.enabled && sync[role] && (!sync.respectIndividual || !individual)){
            if(role==="foreground")return root.sharedModuleText
            if(role==="accent")return root.sharedModuleAccent
            if(role==="muted")return root.sharedModuleMuted
            if(role==="background")return root.sharedModuleBackground
        }
        if(individual==="wallpaper")return ThemeService.dynamicColors?.accent || root.accent
        if(individual==="accent")return root.accent
        return individual && /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(individual)?individual:fallback
    }
    function sidebarTextColour(id:string,fallback:color):color {
        const value=SettingsService.sidebarTextColours[id]
        if(value==="wallpaper")return ThemeService.dynamicColors?.accent || root.accent
        if(value==="accent")return root.accent
        return value && /^#[0-9a-fA-F]{6}$/.test(value)?value:fallback
    }
    function sidebarColour(id:string,fallback:color):color {
        const value=SettingsService.sidebarColours[id]
        if(value==="wallpaper")return ThemeService.dynamicColors?.accent || root.accent
        if(value==="accent")return root.accent
        return value && /^#[0-9a-fA-F]{6}$/.test(value)?value:fallback
    }
    function modernIn(window:var):bool {return root.settingsWindow(window) && SettingsDesignService.modern}
    function formaIn(window:var):bool {return root.settingsWindow(window) && SettingsDesignService.forma}
    function colourIn(window:var,key:string,fallback:color):color {return root.formaIn(window)?SettingsDesignService.style[key]||fallback:fallback}
    function radiusIn(window:var,key:string,fallback:real):real {return root.formaIn(window)?SettingsDesignService.style[key]??fallback:fallback}
    function textIn(window:var):color {return root.settingsWindow(window)?(SettingsDesignService.forma?SettingsDesignService.style.textColor:root.text):root.moduleColour("_shared","foreground",root.text)}
    function mutedIn(window:var):color {return root.settingsWindow(window)?(SettingsDesignService.forma?SettingsDesignService.style.mutedColor:root.textMuted):root.moduleColour("_shared","muted",root.textMuted)}
    function fontIn(window:var):string {return root.settingsWindow(window) && SettingsDesignService.forma && SettingsDesignService.style.bodyFont?SettingsDesignService.style.bodyFont:root.fontFamily}
    function controlRadiusIn(window:var,fallback:real):real {return root.settingsWindow(window) && SettingsDesignService.forma?SettingsDesignService.style.controlRadius:fallback}
    // Settings alone can use a neutral accent; other shell surfaces keep theirs.
    function settingsWindow(window: var): bool { return !!window && window.settingsPalette === true }
    function accentIn(window: var): color {
        if(!root.settingsWindow(window))return root.moduleColour("_shared","accent",root.accent)
        return root.settingsWindow(window) && SettingsService.settingsDesign.useThemeAccent === false
            ? (SettingsDesignService.style.accentColor || "#b8c9df") : root.accent
    }
    function accentTextIn(window: var): color {
        if(!root.settingsWindow(window) && SettingsService.moduleColourSync.enabled && SettingsService.moduleColourSync.accent){const c=root.accentIn(window);return c.r*.299+c.g*.587+c.b*.114>.58?"#101418":"#ffffff"}
        if(root.formaIn(window)){const c=Qt.alpha(root.accentIn(window),1);return c.r*.299+c.g*.587+c.b*.114>.58?"#132016":"#f5faf2"}
        return root.settingsWindow(window) && SettingsService.settingsDesign.useThemeAccent === false
            ? "#121923" : root.accentText
    }
    function accentHoverIn(window: var): color {
        if(root.formaIn(window))return Qt.lighter(root.accentIn(window),1.1)
        return root.settingsWindow(window) && SettingsService.settingsDesign.useThemeAccent === false
            ? "#d1ddec" : root.accentHover
    }
    function controlSizeIn(window: var, fallback: real): real {
        return root.settingsWindow(window) ? Math.max(fallback, SettingsService.settingsDesign.controlHeight || 0) : fallback
    }
    function textSizeIn(window: var, fallback: real): real {
        return root.settingsWindow(window) ? Math.max(fallback, SettingsDesignService.style.controlFontSize || 0)*(SettingsDesignService.forma?SettingsDesignService.style.textScale/100:1) : fallback
    }
    function styleIn(window: var): string {
        return !!window && window.glassy === true && !SettingsService.gameMode
            ? (window.groundStyle ?? root.surfaceStyle) : "classic"
    }

    function surfaceIn(window: var): color {
        if (root.settingsWindow(window) && SettingsService.settingsDesign.navigation === "studio")
            return SettingsDesignService.style.fieldBackground || root.veilOf(root.styleIn(window))
        return root.veilOf(root.styleIn(window))
    }

    function surfaceHoverIn(window: var): color {
        if(root.settingsWindow(window) && SettingsDesignService.forma)return SettingsDesignService.style.hoverColor
        if (root.settingsWindow(window) && SettingsService.settingsDesign.navigation === "studio")
            return SettingsDesignService.style.sidebarBackground || root.veilHoverOf(root.styleIn(window))
        return root.veilHoverOf(root.styleIn(window))
    }

    function borderIn(window: var): color {
        if (root.settingsWindow(window) && SettingsService.settingsDesign.navigation === "studio")
            return SettingsDesignService.style.borderColor || root.veilLineOf(root.styleIn(window))
        return root.veilLineOf(root.styleIn(window))
    }
    // The outline of the island, the capsules and the desk's widgets: the
    // hairline on solid, a line of light on glass.
    readonly property color islandRim: root.rimOf(root.surfaceStyle)
    // A see-through ground under the pointer: the same glass, a little lit.
    readonly property color islandGroundLit: Qt.tint(root.islandGround, Qt.rgba(1, 1, 1, 0.10))
    // Under the bar's icons when its sides are on the wallpaper.
    readonly property color barShadow: "#000000"
    readonly property int barShadowReach: SettingsService.barShadowRange
    // An empty workspace there: white held back, not the dim grey made for
    // a black ground.
    readonly property color barInkDim: Qt.rgba(1, 1, 1, 0.72)
    // The glass style's thick edge (`GlassSheen`): light caught inside the
    // rim, and falling from the top edge.
    readonly property real glassEdge: 0.12
    readonly property color glassSheen: Qt.rgba(1, 1, 1, 0.10)

    // The same, by style: liquid catches more of it, from one side.
    function edgeOf(style: string): real {
        return style === "liquid-old" ? 0.22 + SettingsService.liquidShine * 0.0042 : root.glassEdge
    }

    // Liquid is lit from one side (`LitEdge`): its rim and thick edge are full
    // at the top-left and bottom-right corners and fade to `litTrace` toward
    // the other two.
    function litOf(style: string): bool {
        return style === "liquid-old"
    }

    readonly property real litRim: 0.18 + SettingsService.liquidShine * 0.0055
    readonly property real litTrace: 0.02 + SettingsService.liquidShine * 0.0005

    function sheenOf(style: string): color {
        return style === "liquid-old" ? Qt.rgba(1, 1, 1, 0.025 + SettingsService.liquidShine * 0.0011) : root.glassSheen
    }

    // An application's icon, from the set `shell.qml` names. Some apps are
    // drawn there under another name, and every file manager as somebody
    // else's, so those ask for the picture meant for them.
    readonly property var appIconAliases: ({
        "vesktop": "Vesktop",
        "org.gnome.Nautilus": "impasto-files",
        "thunar": "impasto-files",
        "org.xfce.thunar": "impasto-files"
    })

    function appIcon(name: string): string {
        return Quickshell.iconPath(root.appIconAliases[name] ?? name, true)
    }

    // How far down a shape that light reaches, in pixels, so a short pane and
    // a tall one are lit alike; a shape shorter than this keeps some at its
    // foot.
    readonly property int glassSheenDepth: 48

    // ── SEMANTIC COLOURS ────────────────────────────────────────────────────

    property color background: "#0c0c0c"
    property color surface: "#141414"
    property color surfaceHover: "#202020"
    property color border: "#282828"
    property color text: "#ffffff"
    property color paletteMuted: "#8e8e93"
    // The palette's muted grey, lifted toward the text while any ground is
    // liquid: over a pale wallpaper that glass measures mid grey, where the
    // palette's own grey is under 2:1.
    readonly property color textMuted: root.litOf(root.surfaceStyle)
            || root.litOf(root.dockStyle) || root.litOf(root.deskStyle)
        ? Qt.tint(root.paletteMuted, Qt.alpha(root.text, root.mutedLift))
        : root.paletteMuted
    readonly property real mutedLift: 0.45
    property color accent: "#0a84ff"
    property color accentHover: "#409cff"
    property color accentText: "#ffffff"

    property color red: "#ff453a"
    property color green: "#32d74b"
    property color yellow: "#ffd60a"
    property color blue: "#0a84ff"

    // Status indicators are fixed: a wallpaper-derived accent must not change
    // what a battery ring means.
    readonly property color indicator: "#ffffff"
    readonly property color indicatorDim: "#4d4d4d"
    readonly property color indicatorGood: "#32d74b"
    readonly property color indicatorWarn: "#ffd60a"
    readonly property color indicatorBad: "#ff453a"
    readonly property color indicatorTimer: "#64d2ff"

    // What is being watched or listened to, in a phone's colours for the
    // same thing: the microphone orange, the camera green, the screen blue.
    // Fixed, as warnings are.
    readonly property color privacyMicrophone: "#ff9f0a"
    readonly property color privacyCamera: root.indicatorGood
    readonly property color privacyScreen: "#0a84ff"

    // One coat per pet species. Fixed, so a pet looks the same on every
    // wallpaper and palette.
    readonly property color petDot: "#cba6f7"
    readonly property color petSprout: "#a6e3a1"
    readonly property color petEmber: "#f38ba8"
    readonly property color petSol: "#f9e2af"
    readonly property color petDrift: "#89b4fa"

    // Ground and ink over photographs. Fixed, since the ground is always dark.
    readonly property color scrim: "#bf000000"
    // Not `onScrim`: QML parses "on" + capital as a signal handler.
    readonly property color scrimText: "#ffffff"
    readonly property color hairline: "#20ffffff"

    // Sticky-note paper: a palette tint washed towards white, with ink that
    // stays dark in every palette.
    readonly property color paperWash: "#c4ffffff"
    readonly property color paperInk: "#1c1c1e"
    readonly property color paperInkMuted: "#8a1c1c1e"
    readonly property color paperLine: "#261c1c1e"
    readonly property int paperRadius: 10

    // Sticker widgets: a die-cut edge of vinyl white, fixed like the island's
    // black, around a palette hue washed towards it; what is printed on one
    // is the same hue darkened. The edge is a share of the sticker's short
    // side, the lean a sticker's largest tilt in degrees.
    readonly property color stickerPaper: "#fbf7ee"
    readonly property real stickerWash: 0.45
    readonly property real stickerDeep: 0.62
    readonly property real stickerEdge: 0.028
    readonly property real stickerLean: 5

    // Contribution graph, empty to busiest. GitHub's dark ramp, fixed across
    // palettes; the empty step is lifted off black so it reads as a cell.
    readonly property var githubLevels: [
        "#26292e", "#0e4429", "#006d32", "#26a641", "#39d353"
    ]

    // Ranked groups in a chart, as steps of the accent: one hue, so no two
    // groups collide whatever the palette. Everything past them is `text` at
    // `rankRest`.
    readonly property var rankShades: [1, 0.62, 0.4, 0.24]
    readonly property real rankRest: 0.14

    function rankColor(rank: int): color {
        return root.rankColorIn(rank, root.accent, root.text)
    }

    // The same steps off another accent and text, a widget's `ink`.
    function rankColorIn(rank: int, accent: color, text: color): color {
        return rank >= 0 && rank < root.rankShades.length
            ? Qt.rgba(accent.r, accent.g, accent.b, root.rankShades[rank])
            : Qt.rgba(text.r, text.g, text.b, root.rankRest)
    }

    readonly property int paletteTransition: root.activeId === "adaptive" ? 0 : 260

    Behavior on background   { ColorAnimation { duration: root.paletteTransition } }
    Behavior on surface      { ColorAnimation { duration: root.paletteTransition } }
    Behavior on surfaceHover { ColorAnimation { duration: root.paletteTransition } }
    Behavior on border       { ColorAnimation { duration: root.paletteTransition } }
    Behavior on text         { ColorAnimation { duration: root.paletteTransition } }
    Behavior on paletteMuted { ColorAnimation { duration: root.paletteTransition } }
    Behavior on accent       { ColorAnimation { duration: root.paletteTransition } }
    Behavior on accentHover  { ColorAnimation { duration: root.paletteTransition } }
    Behavior on accentText   { ColorAnimation { duration: root.paletteTransition } }

    // ── METRICS ─────────────────────────────────────────────────────────────

    // The bar's scale. Ring chips, the resting island and the one-capsule
    // band are all one capsule tall.
    readonly property real barScale:Math.max(.5,Math.min(1.5,SettingsService.barScale/100))
    readonly property int capsuleHeight: SettingsService.barHeight
    readonly property int barTopMargin: SettingsService.barMargin
    // Floating islands keep their own breathing room even with a flush bar.
    readonly property int floatingIslandMargin: Math.max(root.barTopMargin, SettingsService.islandFloatingGap)
    readonly property int islandTopMargin: SettingsService.notched ? 0 : root.floatingIslandMargin
    readonly property int capsuleSpacing: 8

    // Exclusive zone: exactly what the bar paints. Hyprland adds `gaps_out`
    // below it, so reserving more leaves a larger top gap than on the other
    // edges.
    readonly property int barReserve: Math.max(root.barTopMargin, root.islandTopMargin) + root.capsuleHeight

    // Where the bar's input region ends: 8 px of slack under the capsules.
    readonly property int barBand: root.barReserve + 8

    // ── DESKTOP GRID ────────────────────────────────────────────────────────
    //
    // Widgets span whole cells. The gutter matches Hyprland's `gaps_out`.
    // A square is at least `desktopCell` and grows up to `desktopCellLargest`
    // so the board's margin is the same on all four sides
    // (`DesktopService.gridFor`). At the least, a 4 × 2 widget is 398 × 190,
    // which fits a two-row module card with one gutter around it; a larger
    // detail needs a larger cell.
    readonly property int desktopCell: 86
    readonly property int desktopCellLargest: 108
    readonly property int desktopGutter: 18
    readonly property int desktopStride: root.desktopCell + root.desktopGutter

    // ── CONTROL CENTRE GRID ─────────────────────────────────────────────────
    //
    // Up to 6 × 8 cells (`ControlsService.columns`, `rows`); one cell is one
    // toggle tile, and blocks span whole cells. A round button in the session
    // and shortcut blocks, and the gap between two: six across two cells.
    readonly property int centreColumns: 6
    readonly property int centreRows: 8
    readonly property int centreButton: 42
    readonly property int centreButtonGap: 8
    readonly property int centreCellWidth: 140
    readonly property int centreCellHeight: 64
    readonly property int centreGutter: 12
    readonly property int centreStrideX: root.centreCellWidth + root.centreGutter
    readonly property int centreStrideY: root.centreCellHeight + root.centreGutter

    // The pager strip (dots and chevrons) along the bottom of a paged block.
    readonly property int centrePagerLane: 18

    readonly property int panelPadding: 20

    // A page the control centre opens into (sound): its heading, a
    // section's title, a row (a level or a choice), the gap between rows and
    // between sections, and the column every row's name takes, so every bar
    // on a page starts at the same place.
    readonly property int detailHeader: 38
    readonly property int detailTitle: 24
    readonly property int detailRow: 36
    readonly property int detailRowGap: 4
    readonly property int detailGap: 14
    readonly property int detailLabel: 128

    // The height of a titled section of `rows` rows, with its gap above.
    function detailSection(rows: int): int {
        return root.detailGap + root.detailTitle
            + rows * root.detailRow + Math.max(0, rows - 1) * root.detailRowGap
    }

    // ── MODULE CARDS ────────────────────────────────────────────────────────
    //
    // A module's detail (`ModuleCard`): the island's rim around it, its own
    // padding, a heading on a mark, then rows of one height — a limit, a fact,
    // a level or a choice — so every card has the same margins and one card
    // can be sized from its count of rows before it is built.
    readonly property int cardInset: 4
    readonly property int cardPadding: 16
    readonly property int cardMark: 44
    readonly property int cardGap: 14
    readonly property int cardRow: 22
    readonly property int cardRowGap: 8
    readonly property int cardLabel: 84
    readonly property int cardWidth: 380
    // The one figure a heading may carry on its right.
    readonly property int cardFigure: 24

    // The height of a card with `rows` rows under its heading, and `extra`
    // pixels of anything taller than a row.
    function cardHeight(rows: int, extra: int): int {
        const body = rows * root.cardRow + Math.max(0, rows - 1) * root.cardRowGap + (extra ?? 0)
        return 2 * (root.cardInset + root.cardPadding) + root.cardMark
            + (body > 0 ? root.cardGap + body : 0)
    }

    // ── DOCK ────────────────────────────────────────────────────────────────
    //
    // Everything scales off the icon size. The margin matches `gaps_out`.
    readonly property int dockIcon: SettingsService.dockIconSize
    // Little room round the icons, so the icon is most of the dock.
    readonly property int dockPadding: 6
    readonly property int dockGap: root.capsuleSpacing
    readonly property int dockMargin: root.desktopGutter

    // The icons are centred across the dock; the running dot sits in the
    // padding on the screen-edge side. An icon is drawn `dockInset` inside its
    // square, so the dot clears both it and the rim.
    readonly property int dockDot: 4
    readonly property int dockInset: 1

    // The launcher button is a glyph narrower than an icon, so its square is
    // too: the mark with room either side, or it reads as a gap.
    readonly property int dockLauncher: Math.round(root.dockIcon * 0.7)
    readonly property int dockThickness: root.dockIcon + 2 * root.dockPadding

    // Screen-edge strip a hidden dock still listens on.
    readonly property int dockReveal: 4

    // Fixed width so a long window title does not stretch the menu.
    readonly property int dockMenuWidth: 250
    readonly property int dockMenuRow: 30
    readonly property int dockMenuPadding: 6

    readonly property int dockRadius: root.desktopRadius

    // Hover scale when the dock does not magnify. Small enough that the
    // neighbours never move.
    readonly property real dockLift: 1.125

    // Magnifying, the icon under the pointer grows to this, and the swell
    // falls off over this many icons either side.
    readonly property real dockMagnify: 1.7
    readonly property real dockReach: 2.5

    // Matches Hyprland's `rounding`: widgets sit among windows.
    readonly property int desktopRadius: 22
    // The screen's own corners, when they are rounded: the same curve.
    readonly property int screenRadius: root.desktopRadius

    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 18
    readonly property int radiusPill: 999

    // Corner radius for pictures, as a fraction of the box. They range from
    // 20 px to 58 px, and no fixed radius looks right at both ends.
    readonly property real pictureCorner: 0.24

    // Where the notch meets the screen edge.
    readonly property real notchShoulderRoundingPower:Math.max(1,Math.min(8,SettingsService.notchShoulderRoundingPower))
    readonly property real notchRoundingPower:Math.max(1,Math.min(8,SettingsService.notchRoundingPower))
    readonly property real radiusNotch: SettingsService.notchShoulderRadius/2

    // ── FIXED COLOURS ───────────────────────────────────────────────────────
    //
    // For what can be told to keep one colour whatever the palette does (the
    // cursor, the sound bars); "palette" beside them is the accent.
    readonly property var fixedColours: [
        { id: "#000000", label: "Black" },
        { id: "#ffffff", label: "White" },
        { id: "#e5484d", label: "Red" },
        { id: "#f76b15", label: "Orange" },
        { id: "#f5c518", label: "Yellow" },
        { id: "#46a758", label: "Green" },
        { id: "#3b82f6", label: "Blue" },
        { id: "#8b5cf6", label: "Purple" },
        { id: "#e93d82", label: "Pink" }
    ]

    // ── SPECTRUM ────────────────────────────────────────────────────────────
    //
    // Sound bars along a screen edge, as they are placed: a bar
    // `spectrumBar` wide with `spectrumGap` between, reaching `spectrumReach`
    // in from the edge at full level and `spectrumFloor` in silence. Each strip
    // can change the three. Solid at the edge, fading to `spectrumTip` at the
    // end.
    readonly property int spectrumBar: 10
    readonly property int spectrumGap: 6
    readonly property int spectrumReach: 170
    readonly property int spectrumFloor: 3
    readonly property real spectrumBase: 0.95
    readonly property real spectrumTip: 0.25

    // cava reports linear amplitude; a fractional power keeps quiet passages
    // visible.
    readonly property real spectrumCurve: 0.55

    // ── SHADOW ──────────────────────────────────────────────────────────────
    //
    // Shared by Hyprland's `decoration:shadow` (CompositorService) and the
    // bar's own capsule shadow, so both sit at the same height. Only drawn
    // when the setting is on.
    readonly property int shadowRange: 14
    readonly property real shadowOpacity: 0.5
    readonly property int windowShadowRange: Math.max(0, SettingsService.windowShadowRange)
    readonly property real windowShadowOpacity: Math.max(0, Math.min(1, SettingsService.windowShadowIntensity / 100))
    readonly property int windowShadowSpread: Math.min(4, Math.floor(root.windowShadowRange / 3))
    readonly property real barShadowBoost:Math.max(1,Math.min(2,SettingsService.barShadowIntensity/100))
    readonly property real barShadowOpacity: Math.max(0, Math.min(1, SettingsService.barShadowIntensity / 100))
    readonly property color shadowColor: "#000000"

    // Bar only. A Gaussian is at half strength on the edge of its source
    // shape, while Hyprland's shadow is at full strength against the window;
    // blurring a slightly grown copy moves the half-way point outside the
    // capsule.
    readonly property int shadowSpread: 4

    // The bar's capsules are small and have open wallpaper on every side, so
    // the same reach reads much heavier. Scale the reach, keep the darkness.
    readonly property real shadowBarScale: 0.6
    readonly property int shadowBarRange: Math.max(0, SettingsService.barShadowRange)
    readonly property int shadowBarSpread: Math.min(root.shadowBarRange,
        Math.round(root.shadowSpread * root.shadowBarScale))

    // ── TYPOGRAPHY ──────────────────────────────────────────────────────────

    // Qt matches one family and never a list: a comma-separated stack names
    // no installed font, and fontconfig's default sans is drawn instead. Both
    // settings hold a stack, so Qt is handed the first family in it that
    // exists, or the generic name at the end when none of them do.
    readonly property var installedFonts: Qt.fontFamilies()

    function fontOf(stack: string): string {
        const names = stack.split(",")
        for (const name of names) {
            const family = name.trim()
            if (family !== "" && root.installedFonts.indexOf(family) !== -1)
                return family
        }
        return names[names.length - 1].trim()
    }

    readonly property string fontFamily: root.fontOf(SettingsService.fontFamily)
    readonly property string fontMono: root.fontOf(SettingsService.fontMono)

    // Type drawn very large: Inter's display cut, tighter and finer at that
    // size, when the family is Inter; any other family as it is.
    readonly property string fontDisplay: root.fontFamily === "Inter"
        ? root.fontOf("Inter Display, Inter") : root.fontFamily

    // Script face for the shell's own name, shipped with it.
    readonly property string fontSignature:
        root.fontOf(`Grape Nuts, Georgia, ${root.fontFamily}`)

    // Note bodies: handwriting unless switched off.
    readonly property string fontHand: SettingsService.notesBodyFont === "@clock" ? root.fontFamily
        : SettingsService.notesBodyFont.trim() !== ""
        ? root.fontOf(SettingsService.notesBodyFont) : SettingsService.notesHandwriting
        ? root.fontSignature : root.fontFamily

    readonly property int fontSizeLabel: 10
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeRegular: 13
    readonly property int fontSizeMedium: 14
    readonly property int fontSizeLarge: 16

    // Desktop widgets are read from further away. `fontSizeDisplay` is for
    // faces that are a single number (the large clocks).
    readonly property int fontSizeWidget: 30
    readonly property int fontSizeDisplay: 68

    // ── MOTION ──────────────────────────────────────────────────────────────

    // Game mode stills the shell whatever the pace says: nothing morphs and
    // nothing loops while it is on.
    readonly property real motion: SettingsService.gameMode ? 0 : SettingsService.motionScale / 100
    readonly property bool lively: !SettingsService.gameMode
    // The shell's own shadows are blurred on the GPU, so game mode drops them
    // with the compositor's; the settings come back when it is off.
    readonly property bool barShadowShown: SettingsService.barShadow && !SettingsService.gameMode
        && root.shadowBarRange > 0 && root.barShadowOpacity > 0
    readonly property bool dockShadowShown: SettingsService.dockShadow && !SettingsService.gameMode
    readonly property bool widgetShadowShown: SettingsService.widgetShadow && !SettingsService.gameMode

    readonly property var easingCurves: [
        {id:"InOutCubic",label:"Cinematic",type:Easing.InOutCubic},
        {id:"OutSine",label:"Gentle",type:Easing.OutSine},
        { id: "OutCubic", label: "Smooth",  type: Easing.OutCubic },
        { id: "OutQuint", label: "Snappy",  type: Easing.OutQuint },
        { id: "OutBack",  label: "Springy", type: Easing.OutBack },
        { id: "OutBounce", label: "Gentle bounce", type: Easing.OutCubic },
        { id: "OutElastic", label: "Elastic", type: Easing.OutCubic },
        { id: "InOutBack", label: "Jelly", type: Easing.OutCubic },
        { id: "FadeSoft", label: "Soft Fade", type: Easing.OutCubic },
        { id: "FadeRise", label: "Fade & Rise", type: Easing.OutCubic },
        { id: "FadeZoom", label: "Fade & Zoom", type: Easing.OutCubic },
        { id: "Linear",   label: "Flat",    type: Easing.Linear }
    ]

    readonly property int easing: {
        const curve = root.easingCurves.find(entry => entry.id === SettingsService.motionCurve)
        return curve ? curve.type : Easing.OutCubic
    }

    // A preset writes `motionScale` and `motionCurve` together; there is no
    // stored preset key.
    readonly property var motionPresets: [
        {"id": "video-modules-safe", "label": "Video reference · All modules", "note": "Measured module expansion and switching · original hover animation retained", "scale": 100, "curve": "OutCubic", "group": "reference", "settings": {"shellExpandDuration": 375, "shellCloseMode": "parallel", "shellFadeDuration": 65, "shellShapeSpring": 0, "shellMovement": 100, "islandHoverOpenDelay": 25, "islandHoverCloseDelay": 20, "shellSpring": {"mode": "traced", "moduleVideo": true, "enabled": true, "damping": 82, "openFrequency": 28, "closeFrequency": 24, "panelFrequency": 22, "openDuration": 340, "closeDuration": 360, "panelDuration": 375, "moduleCloseDuration": 400, "switchDuration": 375, "wideDuration": 300, "verticalDuration": 333, "itemStagger": 18, "movingItems": true, "contentDelay": 45, "contentFade": 75, "restFade": 50, "closeContentFade": 85}}, "moduleOverrides": {"all": {"followShell": true}, "bar": {"followShell": true}, "summary": {"followShell": true}}},
        {id:"video-reference",label:"Video reference (traced)",note:"Traced from your clip · separate width, height and switching paths",scale:100,curve:"OutCubic",group:"reference",settings:{shellExpandDuration:330,shellCloseMode:"parallel",shellFadeDuration:65,shellShapeSpring:0,shellMovement:100,islandHoverOpenDelay:25,islandHoverCloseDelay:20,shellSpring:{mode:"traced",wideDuration:230,verticalDuration:310,enabled:true,damping:82,openFrequency:28,closeFrequency:24,panelFrequency:22,openDuration:340,closeDuration:360,panelDuration:370,switchDuration:350,itemStagger:18,movingItems:true,contentDelay:45,contentFade:75,restFade:50,closeContentFade:85}},moduleOverrides:{all:{followShell:true},bar:{followShell:true},summary:{followShell:true}}},
        {id:"rapid-glide",label:"Rapid glide",scale:100,curve:"OutQuint",group:"fast",settings:{shellExpandDuration:150,shellFadeDuration:55,shellShapeSpring:0,shellMovement:70,islandHoverOpenDelay:15,islandHoverCloseDelay:35,shellCloseMode:"parallel"}},
        {id:"quick-smooth",label:"Quick smooth",scale:100,curve:"OutCubic",group:"fast",settings:{shellExpandDuration:185,shellFadeDuration:65,shellShapeSpring:0,shellMovement:80,islandHoverOpenDelay:25,islandHoverCloseDelay:50,shellCloseMode:"parallel"}},
        {id:"swift-spring",label:"Swift spring",scale:100,curve:"OutBack",group:"fast",settings:{shellExpandDuration:195,shellFadeDuration:60,shellShapeSpring:30,shellMovement:60,islandHoverOpenDelay:20,islandHoverCloseDelay:45,shellCloseMode:"parallel"}},
        {id:"fast-fade",label:"Fast fade",scale:100,curve:"FadeSoft",group:"fast",settings:{shellExpandDuration:165,shellFadeDuration:60,shellShapeSpring:0,shellMovement:0,islandHoverOpenDelay:15,islandHoverCloseDelay:35,shellCloseMode:"parallel"}},
        {id:"micro-expand",label:"Micro expand",scale:100,curve:"OutCubic",group:"fast",settings:{shellExpandDuration:120,shellFadeDuration:45,shellShapeSpring:0,shellMovement:40,islandHoverOpenDelay:0,islandHoverCloseDelay:20,shellCloseMode:"parallel"}},
        { id: "smooth",  label: "Smooth",  scale: 100, curve: "OutCubic" },
        { id: "snappy",  label: "Snappy",  scale: 70,  curve: "OutQuint" },
        { id: "springy", label: "Springy", scale: 110, curve: "OutBack" },
        { id: "off",     label: "None",    scale: 0,   curve: "Linear" },
        { id: "gentle-bounce", label: "Gentle bounce", scale: 95, curve: "OutBounce" },
        { id: "elastic", label: "Elastic", scale: 120, curve: "OutElastic" },
        { id: "jelly", label: "Jelly", scale: 110, curve: "InOutBack" },
        { id: "fade-soft", label: "Soft Fade", scale: 100, curve: "FadeSoft" },
        { id: "fade-rise", label: "Fade & Rise", scale: 100, curve: "FadeRise" },
        { id: "fade-zoom", label: "Fade & Zoom", scale: 100, curve: "FadeZoom" }
    ]

    function easingTypeOf(id: string): int {
        const curve = root.easingCurves.find(entry => entry.id === id)
        return curve ? curve.type : Easing.OutCubic
    }

    readonly property int durationFast: Math.round(140 * root.motion)
    readonly property int durationMedium: Math.round(200 * root.motion)
    readonly property int durationMorph: Math.round(SettingsService.shellExpandDuration * root.motion)

    // How long anything that screenshots the screen (lock, picker, capture)
    // waits after closing the island: the morph plus a couple of frames.
    readonly property int durationIslandGone: root.durationMorph + 40


    // ── CAPTURE ─────────────────────────────────────────────────────────────

    // Wash outside the selection. Neutral black: a tinted wash would recolour
    // the screenshot being cropped.
    readonly property color captureWash: "#99000000"

    readonly property int captureBarMargin: root.barTopMargin + 14

    // ── APPLICATION ─────────────────────────────────────────────────────────

    readonly property var tokens: [
        "background", "surface", "surfaceHover", "border", "text", "textMuted",
        "accent", "accentHover", "accentText", "red", "green", "yellow", "blue"
    ]

    // Tokens a palette does not define keep their current value.
    function apply(colors: var, name: string): void {
        if (!colors)
            return
        if (name)
            root.activeName = name
        for (const token of root.tokens) {
            if (colors[token])
                root[token === "textMuted" ? "paletteMuted" : token] = colors[token]
        }
    }
}
