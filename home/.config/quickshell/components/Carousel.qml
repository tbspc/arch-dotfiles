// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C A R O U S E L                                                        │
// │   horizontal carousel · the centred tile enlarged                        │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import "../theme"

// A horizontal strip of tiles with the current one centred and enlarged.
//
// Only `position` animates; each tile derives its offset and scale from its
// distance to it, so a step is one animation and a held arrow key retargets
// it instead of queueing. Delegates are `CarouselTile`s, which read the
// geometry through `parent`.
Item { objectName:"design:Carousel:1";
    id: root

    property var model: []
    property Component delegate
    property bool virtualized: false
    property var tileObjects: ({})
    property bool ready: false

    property int current: 0
    readonly property int count: root.model ? root.model.length : 0

    property int tileWidth: 160
    property int tileHeight: 100
    property real centreScale: 1.25
    property int gap: 12

    // Tiles further than this from the centre are not drawn.
    property real reach: 3

    // The centre tile was clicked, or Enter was pressed.
    signal activated(int index)

    // Fractional while sliding.
    property real position: root.current

    Behavior on position {
        enabled: root.ready
        NumberAnimation { id:slide; duration: Theme.durationMorph; easing.type: Theme.easing }
    }

    property int sampledFrames:0
    property real sampledTime:0
    property real longestFrame:0
    function frameStats():var {return {frames:sampledFrames,averageMs:sampledFrames?1000*sampledTime/sampledFrames:0,worstMs:longestFrame*1000}}
    FrameAnimation {
        running:slide.running
        onRunningChanged:if(running){root.sampledFrames=0;root.sampledTime=0;root.longestFrame=0}
        onTriggered:{root.sampledFrames++;root.sampledTime+=frameTime;root.longestFrame=Math.max(root.longestFrame,frameTime)}
    }
    implicitHeight: Math.ceil(root.tileHeight * root.centreScale)
    clip: true

    // Offset of a tile `distance` steps from the centre. The first step spans
    // half the large tile and half a small one; later steps a small one.
    // Linear in between, so sliding is continuous.
    readonly property real firstStep:
        root.tileWidth * root.centreScale / 2 + root.gap + root.tileWidth / 2
    readonly property real stride: root.tileWidth + root.gap

    function offsetOf(distance: real): real {
        const away = Math.abs(distance)
        const offset = away <= 1
            ? away * root.firstStep
            : root.firstStep + (away - 1) * root.stride
        return distance < 0 ? -offset : offset
    }

    function scaleOf(distance: real): real {
        return 1 + (root.centreScale - 1) * Math.max(0, 1 - Math.abs(distance))
    }

    function goTo(index: int): void {
        if (root.count === 0)
            return
        root.current = Math.max(0, Math.min(root.count - 1, index))
    }

    function step(delta: int): void {
        root.goTo(root.current + delta)
    }

    // Clicking the centre tile activates it; any other tile scrolls to it.
    function press(index: int): void {
        if (index === root.current)
            root.activated(index)
        else
            root.goTo(index)
    }

    // Small catalogues keep ordinary delegates. Large wallpaper lists only
    // construct the visible cards and one neighbour on either side.
    Repeater {
        model: root.virtualized ? [] : root.model
        delegate: root.delegate
    }

    readonly property int firstTile: Math.max(0, Math.floor(root.position - root.reach))
    readonly property int lastTile: Math.min(root.count - 1, Math.ceil(root.position + root.reach))
    readonly property Timer tileSync: Timer { interval:0; onTriggered:root.syncTiles() }
    onFirstTileChanged: if(root.ready) root.tileSync.restart()
    onLastTileChanged: if(root.ready) root.tileSync.restart()
    onVirtualizedChanged: if(root.ready) root.tileSync.restart()
    onModelChanged: {
        if (!root.ready) return
        root.clearTiles()
        root.tileSync.restart()
    }
    onDelegateChanged: {
        if (!root.ready) return
        root.clearTiles()
        root.tileSync.restart()
    }

    function clearTiles(): void {
        const tiles = root.tileObjects ?? ({})
        for (const key of Object.keys(tiles)) {
            const tile=tiles[key]
            if (tile && typeof tile.destroy === "function") tile.destroy()
        }
        root.tileObjects = ({})
    }

    function syncTiles(): void {
        if (!root.ready || !root.virtualized || !root.delegate)
            return
        const tiles=root.tileObjects
        const spare=Object.keys(tiles).filter(key=>Number(key)<root.firstTile||Number(key)>root.lastTile)
        for(let index=root.firstTile;index<=root.lastTile;++index) {
            if(tiles[index])continue
            const old=spare.shift()
            if(old!==undefined) {
                const tile=tiles[old]
                delete tiles[old]
                tile.modelData=root.model[index]
                tile.index=index
                tiles[index]=tile
            } else {
                const tile=root.delegate.createObject(root,{index:index,modelData:root.model[index]})
                if(tile)tiles[index]=tile
            }
        }
        root.tileObjects = tiles
    }

    Component.onCompleted: {
        root.ready = true
        root.syncTiles()
    }

    // Touchpads send many small deltas; accumulate them to one step per 120.
    // A WheelHandler hears only its own `orientation`, vertical unless told,
    // so a sideways swipe needs a second one.
    property real turned: 0

    function turn(delta: real): void {
        root.turned += delta
        while (Math.abs(root.turned) >= 120) {
            root.step(root.turned < 0 ? 1 : -1)
            root.turned -= 120 * Math.sign(root.turned)
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.turn(event.angleDelta.y)
    }

    WheelHandler {
        orientation: Qt.Horizontal
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.turn(event.angleDelta.x)
    }

    // Held and dragged sideways: a step for every tile's width travelled,
    // the strip following the pointer.
    DragHandler {
        property int from: 0

        target: null
        xAxis.enabled: true
        yAxis.enabled: false
        onActiveChanged: if (active) from = root.current
        onTranslationChanged: {
            if (active)
                root.goTo(from - Math.round(translation.x / root.stride))
        }
    }
}
