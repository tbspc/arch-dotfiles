import QtQuick
import "../theme"
import "../services"
import "../bar/modules"
import "../bar/widgets"
import "../bar/island"
import "../lock/common"

// The actual resting face, fed a snapshot instead of changing live settings.
Rectangle { objectName:"design:IslandPresetPreview:1";
    id: root
    property var values: ({})
    property bool editMode:false
    readonly property real previewScale:previewScene.scale
    readonly property var liveGeometry:({barHeight:SettingsService.barHeight,barMargin:SettingsService.barMargin,workspaceStyle:SettingsService.workspaceStyle})
    property var fallbackGeometry:({})
    Component.onCompleted:root.fallbackGeometry=root.liveGeometry
    onLiveGeometryChanged:geometryRefresh.restart()
    Timer{id:geometryRefresh;interval:Math.max(500,Theme.durationMorph+100);onTriggered:root.fallbackGeometry=root.liveGeometry}
    readonly property var configuration: Object.assign({islandChipsEnabled:false},root.editMode?root.liveGeometry:root.fallbackGeometry,root.values,IslandPresetService.complete(root.values),root.values.barGeometry||{})
    implicitHeight: 100
    radius: Theme.radiusMedium
    color: "#242a34"
    clip: true

    Image { objectName:"design:IslandPresetPreview:2";
        anchors.fill: parent
        source: WallpaperService.currentWallpaper ? "file://" + WallpaperService.currentWallpaper : ""
        sourceSize: Qt.size(480, 160)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        opacity: 0.12
    }

    FontMetrics {
        id: clockMetrics
        font.family: Theme.fontFamily
        font.pixelSize: root.configuration.islandClockSize
        font.weight: Font.DemiBold
    }
    FontMetrics {
        id: smallMetrics
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
    }

    function sideWidth(side: string): real {
        const c = root.configuration
        if (c.islandChipsEnabled) return side === "left" ? c.islandPaddingLeft : c.islandPaddingRight
        const pieces = []
        if (c.islandWorkspaces && c.islandWorkspacesPosition === side)
            pieces.push(86 * c.islandWorkspacesScale / 100)
        if (c.islandInternet && c.islandInternetPosition === side)
            pieces.push((c.islandInternetStyle === "wifi" ? 22 : 18) * c.islandInternetScale / 100)
        if (c.islandBluetooth && c.islandBluetoothPosition === side)
            pieces.push(18 * c.islandBluetoothScale / 100)
        if (c.islandSpeaker && c.islandSpeakerPosition === side)
            pieces.push((22 + (c.islandSpeakerPercent ? 6 + smallMetrics.advanceWidth("100%") : 0))
                * c.islandSpeakerScale / 100)
        if (c.islandBattery && c.islandBatteryPosition === side)
            pieces.push((c.islandBatteryMode === "percent" ? smallMetrics.advanceWidth("100%") : 38)
                * c.islandBatteryScale / 100)
        return (side === "left" ? c.islandPaddingLeft : c.islandPaddingRight)
            + pieces.reduce((sum, width) => sum + width, 0) + pieces.length * 8
    }
    readonly property real clockWidth: clockMetrics.advanceWidth(Qt.formatTime(new Date(2000, 0, 1, 23, 59, 59),
        configuration.clockShowsSeconds ? configuration.clockFormat.replace("mm", "mm:ss") : configuration.clockFormat))
        + (configuration.clockShowsDate ? 8 + smallMetrics.advanceWidth("Wed 28 Oct") : 0)
    readonly property real coreWidth: configuration.islandChipsEnabled ? Math.max(clockWidth + 16, IslandChipService.get("clock", configuration).width) : Math.max(configuration.islandPillWidth
        + configuration.islandPaddingLeft + configuration.islandPaddingRight,
        clockWidth + (configuration.islandLayout === "balanced"
            ? 2 * Math.max(sideWidth("left"), sideWidth("right")) : sideWidth("left") + sideWidth("right")))

    readonly property bool previewMedia:(MediaService.playing || root.editMode) && (root.configuration.islandActivities||SettingsService.besideDefaults||[]).includes("media")
    readonly property real naturalWidth:root.coreWidth+(root.previewMedia?128:0)

    function stripRoom(side: string): real {
        if (!configuration.islandChipsEnabled) return 0
        const entries=IslandChipService.list(side,configuration,true)
        const gap=configuration.islandChipGap ?? 12
        return entries.reduce((sum,item)=>sum+item.config.width+gap,0)
            + (root.editMode?0:Math.max(0,...entries.map(item=>Math.abs(item.config.offsetX))))
    }

    Item { objectName:"design:IslandPresetPreview:3";
        id: previewScene
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.configuration.islandChipsEnabled ? root.naturalWidth + 2*Math.max(root.stripRoom("left"),root.stripRoom("right")) : root.naturalWidth
        height: root.configuration.islandChipsEnabled
            ? Math.max(root.configuration.barHeight, ...IslandChipService.ids.filter(id=>IslandChipService.get(id,root.configuration).enabled).map(id=>{
                const c=IslandChipService.get(id,root.configuration);return c.height+(root.editMode?0:2*Math.abs(c.offsetY))
            })) : root.configuration.barHeight + (root.configuration.islandAttached ? root.configuration.barMargin : 0)
        scale: Math.min(1, (root.width - 24) / width, (root.height-32)/height)
        y: 5+(root.height-32-height*scale)/2
        transformOrigin: Item.Top
        IndividualIslandChips {
            anchors.fill: parent
            configuration: root.configuration
            preview: true
            clockCenter: pill.x+pill.width/2
            clockWidth: pill.width
            clockY: pill.y
            clockHeight: pill.height
        }
    Loader {
        active:!root.editMode && Object.keys(root.values.barElementLayout||{}).length>0
        sourceComponent:ModuleElementStyler {target:previewScene;moduleId:"__preset__";overrideValues:root.values.barElementLayout||{}}
    }
    LockIslandShape {
        id: pill
        notched:root.configuration.islandAttached
        width: root.naturalWidth
        height: root.configuration.barHeight + (root.configuration.islandAttached ? root.configuration.barMargin : 0)
        x: (previewScene.width - width) / 2
        y: (previewScene.height-height)/2
        scale: 1
        transformOrigin: root.configuration.islandAttached ? Item.Top : Item.Center
        radius:root.configuration.islandAttached&&root.configuration.notchCornerRadius>=0?root.configuration.notchCornerRadius:root.values.barStyleOverrides?.rounding??height/2
        shoulder:root.configuration.notchShoulderRadius??12
        topLeftRadius: root.configuration.islandAttached ? 0 : radius
        topRightRadius: root.configuration.islandAttached ? 0 : radius
        color:root.configuration.islandChipsEnabled?"#080a0c":!root.configuration.islandAttached&&Theme.solid?(SettingsService.floatingBarSurface==="black"?"#000000":Theme.islandSurface):Theme.islandGround
        rimColor:Qt.alpha(Theme.text,0.45)
        GlassSheen { shape: pill; visible: Theme.glass }
        IslandRest {
            width:parent.width
            height:root.configuration.barHeight
            anchors.bottom:parent.bottom
            configuration:root.configuration
            preview:true
            designMode:root.editMode
            coreWidth:root.coreWidth
            sideWidth:64
            enabled:false
        }
    }
    }
}
