// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   A P P E A R A N C E   P A N E L                                        │
// │   animated wallpaper, wallpaper and palette picker                       │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts
import Quickshell.Widgets

import "../../theme"
import "../../services"
import "../../components"

// The animated wallpapers, the wallpapers and the palettes, each as a strip
// (`Carousel`): the tile in the middle large, its neighbours stepping away.
// Left and Right slide, Enter applies. Three pages top to bottom: Up and Down
// move between them, the second shortcut opens on the palettes, and the
// chevrons in the footer do it with the pointer.
//
// The wallpaper directories are rescanned whenever the panel opens, so there
// is no refresh button.
FocusScope {
    id: root

    signal closed()
    signal panelRequested(string panel)

    // `wallpaper` or `palette`: the name the panel was opened under, so the
    // shortcut slides a panel that is already open. `shown` is the page on
    // screen, which can also be `animated`, a page with no name of its own.
    property string page: "wallpaper"
    property string shown: root.page
    onPageChanged: root.shown = root.page

    readonly property var pages: ["animated", "wallpaper", "palette"]
    readonly property int shownIndex: root.pages.indexOf(root.shown)
    readonly property bool onPalette: root.shown === "palette"
    readonly property bool onAnimated: root.shown === "animated"

    readonly property int gap: 12
    readonly property int tileWidth: 160
    readonly property int tileHeight: 100
    readonly property real centreScale: 1.25
    readonly property int daub: 12
    readonly property int loadReach: 8

    readonly property Carousel strip:
        root.onPalette ? palettes : root.onAnimated ? animations : wallpapers

    readonly property var centredWallpaper: ThemeService.browsableWallpapers[wallpapers.current] ?? null
    readonly property var centredAnimation: ThemeService.browsableAnimated[animations.current] ?? null
    readonly property var centredPalette: ThemeService.availableThemes[palettes.current] ?? null

    onVisibleChanged:if(visible)Qt.callLater(WallpaperService.scan)

    Component.onCompleted: {
        Qt.callLater(WallpaperService.scan)
        root.forceActiveFocus()
    }

    // Initial values for the strips' `current`, so they open on what is
    // applied instead of sliding there from the first tile. `settle` follows
    // the list when the scan returns a moment after opening.
    readonly property int appliedWallpaper: Math.max(0, ThemeService.browsableWallpapers.findIndex(
        entry => entry.path === WallpaperService.chosen))
    readonly property int appliedAnimation: Math.max(0, ThemeService.browsableAnimated.findIndex(
        entry => entry.path === WallpaperService.chosen))
    readonly property int activePalette: Math.max(0, ThemeService.availableThemes.findIndex(
        entry => entry.id === ThemeService.activeId))

    function settle(): void {
        wallpapers.goTo(root.appliedWallpaper)
        animations.goTo(root.appliedAnimation)
        palettes.goTo(root.activePalette)
    }

    Connections {
        target: WallpaperService
        function onWallpapersChanged(): void { root.settle() }
        function onAnimatedChanged(): void { root.settle() }
        function onChosenChanged(): void { root.settle() }
    }

    Connections {
        target:ThemeService
        function onBrowsableWallpapersChanged():void {root.settle();root.warmVisible()}
        function onBrowsableAnimatedChanged():void {root.settle()}
        function onActiveIdChanged():void {palettes.goTo(root.activePalette)}
    }
    function warmVisible():void {
        const list=ThemeService.browsableWallpapers;const paths=[]
        for(const offset of [0,-1,1,-2,2,-3,3,-4,4]){const entry=list[wallpapers.current+offset];if(entry)paths.push(entry.path)}
        if(JSON.stringify(paths)!==JSON.stringify(WallpaperService.pickerPreviewPaths))WallpaperService.pickerPreviewPaths=paths
    }
    onCentredWallpaperChanged:Qt.callLater(root.warmVisible)

    function apply(): void {
        if (root.onPalette) {
            if (root.centredPalette)
                ThemeService.setTheme(root.centredPalette.id)
        } else if (root.onAnimated) {
            if (root.centredAnimation)
                WallpaperService.apply(root.centredAnimation.path,!ThemeService.wallpaperFilterActive)
        } else if (root.centredWallpaper) {
            WallpaperService.apply(root.centredWallpaper.path,!ThemeService.wallpaperFilterActive)
        }
    }

    // The page `delta` away, up or down. The two named pages go through the
    // island, so its name follows; the animated one is this panel's own.
    function turn(delta: int): void {
        const index = root.shownIndex + delta
        if (index < 0 || index >= root.pages.length)
            return
        root.shown = root.pages[index]
        if (root.shown !== "animated")
            root.panelRequested(root.shown === "palette" ? "palette" : "appearance")
    }

    // Five daubs, in the board's order: the accent and the four status hues.
    // The adaptive entry shows the current theme until the wallpaper has been
    // read.
    function daubsOf(theme:var):var {return ThemeService.previewSwatches(theme)}

    Keys.onLeftPressed: root.strip.step(-1)
    Keys.onRightPressed: root.strip.step(1)
    Keys.onDownPressed: root.turn(1)
    Keys.onUpPressed: root.turn(-1)
    Keys.onReturnPressed: root.apply()
    Keys.onEnterPressed: root.apply()
    Keys.onPressed: event => {
        if(event.key===Qt.Key_F5)WallpaperService.scan()
        else if (event.key === Qt.Key_Home)
            root.strip.goTo(0)
        else if (event.key === Qt.Key_End)
            root.strip.goTo(root.strip.count - 1)
        else if (event.key === Qt.Key_PageUp)
            root.strip.step(-5)
        else if (event.key === Qt.Key_PageDown)
            root.strip.step(5)
        else
            return
        event.accepted = true
    }

    function navigationStatus():var {return {page:root.shown,theme:ThemeService.activeId,filter:SettingsService.wallpaperFilterByTheme,wallpapers:ThemeService.browsableWallpapers.length,animated:ThemeService.browsableAnimated.length,headerBottom:paletteActions.visible?paletteActions.y+paletteActions.height:0,previewTop:pages.y,previewHeight:pages.height,requiredPreviewHeight:Math.ceil(root.tileHeight*root.centreScale),footerTop:footer.y}}

    ColumnLayout { objectName:"design:AppearancePanel:1";
        anchors.fill: parent
        spacing: root.gap

        RowLayout {
            id:paletteActions
            visible:root.onPalette;Layout.fillWidth:true;Layout.minimumHeight:32;Layout.preferredHeight:32;spacing:8
            Text {Layout.fillWidth:true;text:Tr.t("All colours · apps, modules and settings");font.family:Theme.fontFamily;font.pixelSize:12;color:Theme.moduleColour("appearance","muted",Theme.textMuted)}
            PillButton {text:Tr.t("Save theme");onClicked:ThemeService.saveColourTheme("Colour theme "+(SettingsService.savedColourThemes.length+1))}
        }
        // ── STRIPS ──────────────────────────────────────────────────────────

        // All three live here, each parked a strip's height per page away
        // from the one shown, so turning the page slides them past each other.
        Item { objectName:"design:AppearancePanel:2";
            id: pages

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight:Math.ceil(root.tileHeight*root.centreScale)
            clip: true

            Carousel {
                id: wallpapers

                width: pages.width
                height: pages.height
                y: (1 - root.shownIndex) * pages.height
                opacity: root.shownIndex === 1 ? 1 : 0
                current: root.appliedWallpaper
                model: ThemeService.browsableWallpapers
                virtualized: true
                tileWidth: root.tileWidth
                tileHeight: root.tileHeight
                centreScale: root.centreScale
                gap: root.gap
                onActivated: root.apply()

                Behavior on y { NumberAnimation { duration: Theme.durationMorph; easing.type: Theme.easing } }
                Behavior on opacity { NumberAnimation { duration: Theme.durationMorph; easing.type: Theme.easing } }

                delegate: CarouselTile {
                    id: tile

                    readonly property bool applied:
                        tile.modelData.path === WallpaperService.chosen

                    AntialiasedPreview { objectName:"design:AppearancePanel:3";
                        anchors.fill: parent
                        radius: Theme.radiusMedium
                        color: Theme.surfaceIn(QsWindow.window)
                        borderColor: tile.centred ? Theme.moduleColour("appearance","accent",Theme.accent) : Theme.borderIn(QsWindow.window)
                        borderWidth: tile.centred ? 2 : 1

                        Behavior on borderColor { ColorAnimation { duration: Theme.durationFast } }

                        // The service holds the opening cards decoded in
                        // memory. Reuse them synchronously on a cache hit;
                        // further browsing still decodes off the UI thread.
                        Image { objectName:"design:AppearancePanel:4";
                            anchors.fill: parent
                            source: root.shown === "wallpaper" && Math.abs(tile.distance) <= root.loadReach
                                ? `file://${tile.modelData.path}` : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: !WallpaperService.previewReady(tile.modelData.path)
                            cache: true
                            sourceSize: WallpaperService.previewSize
                        }

                        AppliedMark { visible: tile.applied }
                    }
                }
            }

            Text {
                anchors.centerIn:parent;width:parent.width-48
                visible:root.shown==="wallpaper"&&ThemeService.browsableWallpapers.length===0
                text:Tr.t("No wallpapers in this theme yet. Add one in Wallpaper settings, or switch to All wallpapers.")
                horizontalAlignment:Text.AlignHCenter;wrapMode:Text.Wrap
                color:Theme.moduleColour("appearance","muted",Theme.textMuted)
                font.family:Theme.fontFamily;font.pixelSize:12
            }

            Carousel {
                id: animations

                width: pages.width
                height: pages.height
                y: (0 - root.shownIndex) * pages.height
                opacity: root.onAnimated ? 1 : 0
                current: root.appliedAnimation
                model: ThemeService.browsableAnimated
                virtualized: true
                tileWidth: root.tileWidth
                tileHeight: root.tileHeight
                centreScale: root.centreScale
                gap: root.gap
                onActivated: root.apply()

                Behavior on y { NumberAnimation { duration: Theme.durationMorph; easing.type: Theme.easing } }
                Behavior on opacity { NumberAnimation { duration: Theme.durationMorph; easing.type: Theme.easing } }

                // Each tile is the video's poster, the frame it starts from.
                delegate: CarouselTile {
                    id: clip

                    readonly property bool applied:
                        clip.modelData.path === WallpaperService.chosen

                    AntialiasedPreview { objectName:"design:AppearancePanel:5";
                        anchors.fill: parent
                        radius: Theme.radiusMedium
                        color: Theme.surfaceIn(QsWindow.window)
                        borderColor: clip.centred ? Theme.moduleColour("appearance","accent",Theme.accent) : Theme.borderIn(QsWindow.window)
                        borderWidth: clip.centred ? 2 : 1

                        Behavior on borderColor { ColorAnimation { duration: Theme.durationFast } }

                        Image { objectName:"design:AppearancePanel:6";
                            anchors.fill: parent
                            source: root.onAnimated && Math.abs(clip.distance) <= root.loadReach
                                ? `file://${clip.modelData.poster}` : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 320
                            sourceSize.height: 200
                        }

                        AppliedMark { visible: clip.applied }
                    }
                }
            }

            // With no videos yet, where to put them.
            Text { objectName:"design:AppearancePanel:7";
                x: (pages.width - width) / 2
                y: animations.y + (pages.height - height) / 2
                width: pages.width - 4 * root.gap
                visible: ThemeService.browsableAnimated.length === 0
                opacity: animations.opacity
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text:ThemeService.wallpaperFilterActive?Tr.t("No animated wallpapers assigned to this theme. Add the current video in Wallpaper settings."):Tr.t("No animated wallpapers yet. Videos in ~/.local/share/wallpapers/animated show up here.")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.moduleColour("appearance","muted",Theme.textMuted)
            }

            Carousel {
                id: palettes

                width: pages.width
                height: pages.height
                y: (2 - root.shownIndex) * pages.height
                opacity: root.onPalette ? 1 : 0
                current: root.activePalette
                model: ThemeService.availableThemes
                virtualized:true
                tileWidth: root.tileWidth
                tileHeight: root.tileHeight
                centreScale: root.centreScale
                gap: root.gap
                onActivated: root.apply()

                Behavior on y { NumberAnimation { duration: Theme.durationMorph; easing.type: Theme.easing } }
                Behavior on opacity { NumberAnimation { duration: Theme.durationMorph; easing.type: Theme.easing } }

                delegate: CarouselTile {
                    id: card

                    readonly property bool applied: card.modelData.id === ThemeService.activeId

                    Rectangle { objectName:"design:AppearancePanel:8";
                        anchors.fill: parent
                        radius: Theme.radiusMedium
                        color: card.hovered ? Theme.surfaceHoverIn(QsWindow.window) : Theme.surfaceIn(QsWindow.window)
                        border.color: card.centred ? Theme.moduleColour("appearance","accent",Theme.accent) : Theme.borderIn(QsWindow.window)
                        border.width: card.centred ? 2 : 1

                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

                        Column { objectName:"design:AppearancePanel:9";
                            anchors.centerIn: parent
                            spacing: 10

                            Row { objectName:"design:AppearancePanel:10";
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 6

                                Repeater {
                                    model: root.daubsOf(card.modelData)

                                    Rectangle { objectName:"design:AppearancePanel:11";
                                        required property var modelData

                                        width: root.daub
                                        height: root.daub
                                        radius: width / 2
                                        color: modelData
                                        border.color: Theme.hairline
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: Theme.paletteTransition } }
                                    }
                                }
                            }

                            Text { objectName:"design:AppearancePanel:12";
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: card.modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: card.centred ? Font.DemiBold : Font.Normal
                                color: card.centred ? Theme.moduleColour("appearance","foreground",Theme.text) : Theme.moduleColour("appearance","muted",Theme.textMuted)
                            }
                        }

                        AppliedMark { visible: card.applied }
                    }
                }
            }
        }

        // ── FOOTER ──────────────────────────────────────────────────────────

        RowLayout { objectName:"design:AppearancePanel:13";
            id:footer
            Layout.minimumHeight:Math.ceil(Theme.fontSizeSmall*1.4)
            Layout.fillWidth: true
            spacing: root.gap

            Text { objectName:"design:AppearancePanel:14";
                Layout.fillWidth: true
                text: root.onPalette ? (root.centredPalette?.badge ?? "")
                    : root.onAnimated ? (root.centredAnimation?.name ?? "")
                    : (root.centredWallpaper?.name ?? "")
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.moduleColour("appearance","muted",Theme.textMuted)
            }

            PillButton {
                visible:!root.onPalette
                implicitHeight:22
                text:ThemeService.activeId==="adaptive"?Tr.t("Adaptive · All"):SettingsService.wallpaperFilterByTheme?Tr.t("Theme only"):Tr.t("All wallpapers")
                active:ThemeService.wallpaperFilterActive
                enabled:ThemeService.activeId!=="adaptive"
                onClicked:SettingsService.set("wallpaperFilterByTheme",!SettingsService.wallpaperFilterByTheme)
            }

            // Position in the strip; the tile's mark already shows what is
            // applied.
            Text { objectName:"design:AppearancePanel:15";
                text: root.strip.count === 0
                    ? (WallpaperService.scanning ? "Scanning…" : "")
                    : `${root.strip.current + 1}/${root.strip.count}`
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.moduleColour("appearance","muted",Theme.textMuted)
            }

            // Switch pages with the pointer: up, and down, where there is one.
            Door {
                glyph: "󰅃"
                visible: root.shownIndex > 0
                onClicked: root.turn(-1)
            }

            Door {
                glyph: "󰅀"
                visible: root.shownIndex < root.pages.length - 1
                onClicked: root.turn(1)
            }
        }
    }

    component Door: Text {
        id: door

        property string glyph: ""
        signal clicked()

        text: door.glyph
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontSizeRegular
        color: doorMouse.containsMouse ? Theme.moduleColour("appearance","foreground",Theme.text) : Theme.moduleColour("appearance","muted",Theme.textMuted)

        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

        MouseArea {
            id: doorMouse

            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: door.clicked()
        }
    }

    // The check on what is applied, distinct from the accent ring, which
    // marks the position in the strip.
    component AppliedMark: Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 6
        width: 18
        height: 18
        radius: width / 2
        color: Theme.moduleColour("appearance","accent",Theme.accent)

        Text { objectName:"design:AppearancePanel:16";
            anchors.centerIn: parent
            text: "󰄬"
            font.family: Theme.fontMono
            font.pixelSize: 10
            color: Theme.accentText
        }
    }
}
