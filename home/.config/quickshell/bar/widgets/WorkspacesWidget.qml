// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   W O R K S P A C E S   W I D G E T                                      │
// │   the workspace strip · dots, bars, rings or the number written out      │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import Quickshell

import "../../theme"
import "../../services"
import "../../components"

// Three states, by shape and weight alone:
//
//     focused    the accent: a wide pill, the tallest bar, the largest ring,
//                or a pill behind the number
//     occupied   solid but dim, or the number in full
//     empty      dimmer still: a grey dot or bar, a hollow ring, a grey number
//
// The first few are always shown; the rest appear with use. The dot's pill
// and the number's pill slide between positions rather than switching. Drawn
// in the accent: unlike the battery it carries no warning, so it follows the
// palette.
Rectangle {
    id: root

    // Inside the one capsule it drops its own capsule and padding.
    property var motionOffsets:[]
    property bool motionActive:false
    property var configuration:SettingsService
    property bool chromeless: false
    property bool glowActive: SettingsService.islandWorkspacesGlow

    property bool overWallpaper: false
    readonly property color dim: root.overWallpaper ? Theme.barInkDim : Theme.indicatorDim
    // `SettingsService.workspaceStyle` unless a picker draws another.
    property string style: SettingsService.workspaceStyle
    // A still strip for the settings: five, the second focused, the first and
    // third occupied, and nothing to click.
    property bool preview: false

    readonly property bool written: ["numbers", "roman", "kanji", "greek"]
        .indexOf(root.style) >= 0

    // The strip is about the screen it is drawn on: which workspace it is
    // showing and, per screen, which ten are its own. Off a screen of its own
    // it falls back to the focused one.
    readonly property string screenName: root.QsWindow.window?.screen?.name ?? ""
    readonly property int activeId: root.preview ? 2
        : HyprlandService.activeOn(root.screenName) || HyprlandService.activeId

    readonly property int dotSize: root.workspaceSize("dots", "height", 6)
    readonly property int dotWidth: root.workspaceSize("dots", "width", 6)
    readonly property int activeWidth: root.workspaceSize("dots", "activeWidth", 22)
    readonly property int barWidth: root.workspaceSize("bars", "width", 3)
    readonly property int barHeight: root.workspaceSize("bars", "height", 14)
    readonly property int ringSize: root.workspaceSize("rings", "width", 7)
    readonly property int ringHeight: root.workspaceSize("rings", "height", 7)
    readonly property int slotSpacing: root.workspaceSize(root.style, "spacing", root.written ? 2 : 8)
    readonly property real glyphWidthScale: root.workspaceSize(root.style, "width", 100) / 100
    readonly property int glyphHeight: root.workspaceSize(root.style, "height", Theme.fontSizeSmall)
    function workspaceSize(style:string,key:string,fallback:real):real {
        const value=root.configuration.workspaceDimensions?.[style]?.[key]
        return typeof value==="number"?value:SettingsService.workspaceSize(style,key,fallback)
    }
    function dimension(key:string,fallback:real,focused:bool):real {
        return root.workspaceSize(root.style,(focused?"active":"inactive")+key[0].toUpperCase()+key.slice(1),fallback)
    }
    function ink(focused:bool,occupied:bool,fallback:color):color {
        const c=Theme.moduleColour("workspaces",focused?"active":occupied?"occupied":"inactive",fallback)
        if(focused)return c
        const gain=Math.max(0,(occupied?(root.configuration.workspaceOccupiedBrightness??SettingsService.workspaceOccupiedBrightness):(root.configuration.workspaceInactiveBrightness??SettingsService.workspaceInactiveBrightness))/100)
        return Qt.rgba(Math.min(1,c.r*gain),Math.min(1,c.g*gain),Math.min(1,c.b*gain),c.a)
    }
    // Around a number, inside its pill.
    readonly property int glyphPad: 6
    readonly property int pillHeight: Math.min(Theme.capsuleHeight - 4, Math.max(20, root.glyphHeight + 6))

    // The number a workspace is written as, in the written styles.
    function glyphOf(n: int): string {
        switch (root.style) {
        case "roman": {
            const table = [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
            let out = ""
            for (const [value, mark] of table)
                while (n >= value) { out += mark; n -= value }
            return out
        }
        case "kanji": {
            const digits = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
            if (n < 10)
                return digits[n]
            return (n >= 20 ? digits[Math.floor(n / 10)] : "") + "十" + digits[n % 10]
        }
        case "greek":
            return "αβγδεζηθικλμνξοπρστυφχψω".charAt(n - 1) || String(n)
        default:
            return String(n)
        }
    }

    function isShown(n: int): bool {
        return root.preview ? n <= 5 : HyprlandService.isVisibleOn(n, root.screenName)
    }

    function isOccupied(n: int): bool {
        return root.preview ? n === 1 || n === 3 : HyprlandService.isOccupied(n)
    }

    implicitHeight: Theme.capsuleHeight
    // Each slot carries its own gap, so a collapsed one takes no space; the
    // spare gap is subtracted here.
    implicitWidth: layout.implicitWidth - root.slotSpacing
        + (root.chromeless ? 0 : (root.written ? 12 : 20))
    radius: Theme.radiusPill

    color: root.chromeless ? "transparent" : Theme.moduleColour("workspaces","background",Theme.islandGround)
    border.color: Theme.islandRim
    border.width: root.chromeless ? 0 : 1

    GlassSheen {
        shape: root
        visible: Theme.glass && !root.chromeless
    }

    // The written styles' focus: one pill that slides to the focused number
    // and takes its width.
    Rectangle {
        readonly property Item slot: {
            repeater.count
            return repeater.itemAt(root.activeId - 1)
        }

        visible: root.written && slot !== null && slot.shown
        layer.enabled: root.glowActive
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.moduleColour("workspaces","active",Theme.moduleColour("workspaces","accent",Theme.accent))
            shadowOpacity: (root.configuration.workspaceGlowIntensity??SettingsService.workspaceGlowIntensity)/100
            blurMax:64
                        shadowBlur:Math.max(0,Math.min(1,(root.configuration.workspaceGlowRange??SettingsService.workspaceGlowRange)/64))
            shadowScale:(root.configuration.workspaceGlowSpread??SettingsService.workspaceGlowSpread)/100
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            autoPaddingEnabled: true
        }
        x: slot ? layout.x + slot.x + root.slotSpacing / 2+(root.motionOffsets?.[slot.index]?.x||0) : 0
        width: slot ? Math.max(0, slot.width - root.slotSpacing) : 0
        height: root.pillHeight
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset:slot?(root.motionOffsets?.[slot.index]?.y||0):0
        radius: height / 2
        color: Theme.moduleColour("workspaces","active",Theme.moduleColour("workspaces","accent",Theme.accent))

        Behavior on x {
            enabled: !root.preview&&!root.motionActive
            NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
        }
        Behavior on width {
            NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        // Row spacing would still surround a collapsed slot.
        spacing: 0

        // A slot per workspace, shown or not, so arrivals and departures both
        // animate. A Repeater over only the visible ones would destroy items
        // and make the rest jump.
        Repeater {
            id: repeater

            model: root.preview ? 5 : HyprlandService.span

            Item {
                id: slot

                required property int index
                transform:Translate {x:root.motionOffsets?.[slot.index]?.x||0;y:root.motionOffsets?.[slot.index]?.y||0}
                readonly property int workspaceId: slot.index + 1
                readonly property bool shown: root.isShown(slot.workspaceId)
                readonly property bool focused: root.activeId === slot.workspaceId
                readonly property bool occupied: root.isOccupied(slot.workspaceId)
                readonly property bool hovered: mouse.containsMouse

                // What the slot draws, gap aside.
                readonly property real mark: {
                    switch (root.style) {
                    case "bars": return root.dimension("width",root.barWidth,slot.focused)
                    case "rings": return root.dimension("width",root.ringSize+(slot.focused?2:0),slot.focused)
                    case "dots": return root.dimension("width",slot.focused?root.activeWidth:root.dotWidth,slot.focused)
                    default: return Math.max(root.pillHeight, glyph.implicitWidth * root.dimension("width",root.glyphWidthScale*100,slot.focused)/100 + 2 * root.glyphPad)
                    }
                }

                Layout.preferredWidth: slot.shown ? slot.mark + root.slotSpacing : 0
                Layout.preferredHeight: Theme.capsuleHeight
                Layout.alignment: Qt.AlignVCenter
                // A collapsed slot is no width, but a bar, a ring or a number
                // keeps its own and would draw over its neighbour.
                opacity: slot.shown ? 1 : 0
                visible: slot.opacity > 0

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.durationFast }
                }

                // Dots and bars: the accent when focused or hovered, dimmed
                // when occupied, grey when empty.
                Rectangle {
                    visible: root.style === "dots" || root.style === "bars"
                    layer.enabled: root.glowActive && slot.focused
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Theme.moduleColour("workspaces","active",Theme.moduleColour("workspaces","accent",Theme.accent))
                        shadowOpacity: (root.configuration.workspaceGlowIntensity??SettingsService.workspaceGlowIntensity)/100
                        blurMax:64
                        shadowBlur:Math.max(0,Math.min(1,(root.configuration.workspaceGlowRange??SettingsService.workspaceGlowRange)/64))
                        shadowScale:(root.configuration.workspaceGlowSpread??SettingsService.workspaceGlowSpread)/100
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                        autoPaddingEnabled: true
                    }
                    anchors.centerIn: parent
                    width: root.style === "bars" ? root.dimension("width",root.barWidth,slot.focused)
                        : Math.max(0, parent.width - root.slotSpacing)
                    height: root.dimension("height",root.style === "dots" ? root.dotSize : root.barHeight * (slot.focused ? 1 : slot.occupied ? 9/14 : 5/14),slot.focused)
                    radius: Math.min(width, height) / 2

                    color: root.ink(slot.focused || slot.hovered,slot.occupied,slot.focused || slot.hovered || slot.occupied ? Theme.moduleColour("workspaces","accent",Theme.accent) : root.dim)
                    // Dimming separates occupied from focused without a third
                    // shape.
                    opacity: SettingsService.shellColours.workspaces?.[slot.occupied?"occupied":"inactive"] ? 1 : slot.focused || slot.hovered ? 1 : (slot.occupied ? 0.55 : 1)

                    Behavior on height { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                    Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
                }

                // Rings: filled and larger when focused, filled and dim when
                // occupied, hollow when empty.
                Rectangle {
                    visible: root.style === "rings"
                    layer.enabled: root.glowActive && slot.focused
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Theme.moduleColour("workspaces","active",Theme.moduleColour("workspaces","accent",Theme.accent))
                        shadowOpacity: (root.configuration.workspaceGlowIntensity??SettingsService.workspaceGlowIntensity)/100
                        blurMax:64
                        shadowBlur:Math.max(0,Math.min(1,(root.configuration.workspaceGlowRange??SettingsService.workspaceGlowRange)/64))
                        shadowScale:(root.configuration.workspaceGlowSpread??SettingsService.workspaceGlowSpread)/100
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                        autoPaddingEnabled: true
                    }
                    anchors.centerIn: parent
                    width: root.dimension("width",slot.focused ? root.ringSize + 2 : root.ringSize,slot.focused)
                    height: root.dimension("height",slot.focused ? root.ringHeight + 2 : root.ringHeight,slot.focused)
                    radius: Math.min(width, height) / 2

                    color: root.ink(slot.focused || slot.hovered,slot.occupied,slot.focused || slot.hovered ? Theme.accent : slot.occupied ? Qt.alpha(Theme.accent,.55) : "transparent")
                    border.color: root.ink(false,false,root.dim)
                    border.width: slot.focused || slot.hovered || slot.occupied ? 0 : 1.5

                    Behavior on width { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                }

                // Over the wallpaper, a hovered number takes the chips' own
                // hover pill: the accent alone vanishes into a light picture.
                Rectangle {
                    visible: root.written && root.overWallpaper
                    anchors.centerIn: parent
                    width: Math.max(0, parent.width - root.slotSpacing)
                    height: Theme.capsuleHeight - 8
                    radius: height / 2
                    color: Theme.surfaceHoverIn(QsWindow.window)
                    opacity: slot.hovered && !slot.focused ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
                }

                // The written styles: on the sliding pill when focused, in full
                // when occupied, grey when empty.
                Text {
                    id: glyph

                    visible: root.written
                    anchors.centerIn: parent
                    text: root.written ? root.glyphOf(root.preview ? slot.workspaceId
                        : HyprlandService.numberOn(slot.workspaceId, root.screenName)) : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: root.dimension("height",root.glyphHeight,slot.focused)
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                    transform: Scale { origin.x: glyph.width / 2; origin.y: glyph.height / 2; xScale: root.dimension("width",root.glyphWidthScale*100,slot.focused)/100 }
                    color: slot.focused ? Theme.accentText : root.ink(false,slot.occupied,slot.hovered && !root.overWallpaper ? Theme.accent : slot.occupied ? Theme.text : root.dim)

                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                }

                // Fills the slot, gap included; a 6 px target is too small.
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    enabled: !root.preview
                    hoverEnabled: true
                    cursorShape: Qt.ArrowCursor
                    onClicked: HyprlandService.focus(slot.workspaceId)
                }
            }
        }
    }
}
