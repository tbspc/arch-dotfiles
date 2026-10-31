import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../services"
import "../../components"
import "../../components/SpringMotion.js" as SpringMotion
import "../../components/MotionTrace.js" as MotionTrace
import "../modules"
Item {
    id:root
    property bool compact:false
    property var layoutOverride:null
    property string designOverride:""
    readonly property bool custom:root.layout.enabled
    readonly property var layout:Object.assign({},SettingsService.pristine.islandHoverLayout,root.layoutOverride||SettingsService.islandHoverLayout)
    readonly property bool referenceCompact:["reference-compact","reference-media"].includes(root.designOverride||SettingsService.islandHoverDesign)
    property bool preview:false
    property real collapseProgress:0
    property real contentBounceOffset:0
    property var referenceLayout:({})
    function sideFor(role:string):string {
        if(SettingsService.islandChipsEnabled)return IslandChipService.get(role).side
        const key=role==="internet"?"Internet":role[0].toUpperCase()+role.slice(1)
        return SettingsService["island"+key+"Position"]||"right"
    }
    function enabledFor(role:string):bool {
        if(SettingsService.islandChipsEnabled)return IslandChipService.get(role).enabled
        const key=role==="internet"?"Internet":role[0].toUpperCase()+role.slice(1)
        return SettingsService["island"+key]===true
    }
    function itemOffset(role:string,order:int):var {
        const data=root.referenceLayout
        if(!data.active)return {x:0,y:0}
        const p=data.trace?MotionTrace.delayed(data.trace,data.seconds,order*data.stagger,data.duration):SpringMotion.delayed(data.seconds,order*data.stagger,data.duration,data.damping,data.frequency),gap=p-data.progress
        const side=root.sideFor(role)
        const pad=side==="left"?SettingsService.islandPaddingLeft:SettingsService.islandPaddingRight
        const start=data.closing?28:pad,end=data.closing?pad:28
        const delta=side==="left"?-(data.toWidth-data.fromWidth)/2+end-start:(data.toWidth-data.fromWidth)/2-end+start
        const vertical=(data.toHeight-data.fromHeight)/2+(data.closing?-14:14)
        return {x:delta*gap,y:vertical*gap}
    }
    function motionMetrics():var {
        const items=ModuleService.designElements(barFace)
        const result={faceY:barFace.y,parentHeight:root.height,continuous:barFace.continuousPlacement,spread:barFace.spreadLayout,dateTravel:barFace.dateTravel,sides:{internet:root.sideFor("internet"),battery:root.sideFor("battery")}}
        for(const key of ["design:ClockModule:4","design:ClockModule:5","design:ClockModule:6","design:ClockModule:9","design:ClockModule:moving-date","island-internet-left","island-internet-right","island-battery-left","island-battery-right"]) {
            const item=items.find(value=>value.objectName===key)
            if(item)result[key]={x:item.x,y:item.y,width:item.width,visible:item.visible,worldX:item.mapToItem(root,0,0).x,worldY:item.mapToItem(root,0,0).y,worldRight:item.mapToItem(root,item.width,0).x}
        }
        return result
    }
    readonly property var indicatorOffsets:({internet:root.itemOffset("internet",1),battery:root.itemOffset("battery",2),bluetooth:root.itemOffset("bluetooth",1),speaker:root.itemOffset("speaker",2)})
    readonly property var editorOverrides:{
        const values=SettingsService.moduleElements.bar||{},t=root.collapseProgress,result={}
        for(const [key,value] of Object.entries(values)) {
            const item=Object.assign({},value)
            for(const axis of ["x","y"])if(typeof value[axis]==="number")item[axis]=value[axis]*t
            for(const axis of ["widthScale","heightScale","opacity"])if(typeof value[axis]==="number")item[axis]=100+(value[axis]-100)*t
            if(key==="design:ClockModule:6"&&typeof value.fontSize==="number")item.fontSize=root.expandedClockSize
            result[key]=item
        }
        return result
    }
    ModuleElementStyler {target:barFace;moduleId:"bar";overrideValues:root.editorOverrides}
    readonly property var baseBarSettings:{
        const values={},source=IslandPresetService.presentation
        for(const key of SettingsService.storedKeys)
            if(key.startsWith("island")||key.startsWith("workspace")||key.startsWith("clock"))
                values[key]=source[key]??SettingsService.pristine[key]
        return values
    }
    readonly property real expandedClockSize:root.restingClockSize
    readonly property real restingClockSize:SettingsService.moduleElements.bar?.["design:ClockModule:6"]?.fontSize||SettingsService.islandClockSize
    readonly property var workspaceOffsets:Array.from({length:Math.max(5,SettingsService.workspaceCount||10)},(_,i)=>{const offset=root.itemOffset("workspaces",i);const factor=Math.max(.1,SettingsService.islandWorkspacesScale/100);return {x:offset.x/factor,y:offset.y/factor}})
    readonly property var barSettings:{
        if(IslandPresetService.applying)return Object.assign({},IslandPresetService.beforePresentation,{islandChipsEnabled:false})
        return Object.assign({},root.baseBarSettings,{
            islandChipsEnabled:false,
            islandLayout:SettingsService.islandLayout,
            clockFontFamily:SettingsService.moduleElements.bar?.["design:ClockModule:6"]?.fontFamily||root.baseBarSettings.clockFontFamily||Theme.fontFamily,
            islandWorkspaces:root.enabledFor("workspaces"),
            islandWorkspacesPosition:root.sideFor("workspaces"),
            islandInternet:root.enabledFor("internet"),
            islandInternetPosition:root.sideFor("internet"),
            islandBattery:root.enabledFor("battery"),
            islandBatteryPosition:root.sideFor("battery"),
            islandBluetooth:root.enabledFor("bluetooth"),islandBluetoothPosition:root.sideFor("bluetooth"),
            islandSpeaker:root.enabledFor("speaker"),islandSpeakerPosition:root.sideFor("speaker"),
            islandClockSize:root.expandedClockSize,
            clockFormat:root.baseBarSettings.clockFormat,
            clockShowsSeconds:root.baseBarSettings.clockShowsSeconds,
            islandWorkspacesScale:root.custom?(root.baseBarSettings.islandWorkspacesScale||100)*root.layout.workspaceScale/100:root.baseBarSettings.islandWorkspacesScale,
            islandInternetScale:root.custom?(root.baseBarSettings.islandInternetScale||100)*root.layout.signalScale/100:root.baseBarSettings.islandInternetScale,
            islandBatteryScale:root.custom?(root.baseBarSettings.islandBatteryScale||100)*root.layout.batteryScale/100:root.baseBarSettings.islandBatteryScale,
            workspaceDimensions:root.custom&&root.layout.followBarStyle===false?Object.assign({},root.baseBarSettings.workspaceDimensions,{bars:{width:root.layout.workspaceWidth,height:root.layout.workspaceHeight,activeWidth:root.layout.workspaceWidth,activeHeight:root.layout.workspaceHeight,inactiveWidth:root.layout.workspaceInactiveWidth,inactiveHeight:root.layout.workspaceInactiveHeight,occupiedWidth:root.layout.workspaceInactiveWidth,occupiedHeight:root.layout.workspaceInactiveHeight,spacing:root.layout.workspaceGap}}):root.baseBarSettings.workspaceDimensions,
            workspaceStyle:root.baseBarSettings.workspaceStyle,
            islandInternetStyle:root.baseBarSettings.islandInternetStyle,
            islandBatteryMode:root.baseBarSettings.islandBatteryMode,
            islandBatteryIconStyle:root.baseBarSettings.islandBatteryIconStyle,
            clockShowsDate:SettingsService.islandHoverDateFollowBar?SettingsService.clockShowsDate:SettingsService.islandHoverDatePosition!=="hidden"
        })
    }
    ClockModule {
        id:barFace
        transform:Translate {y:root.contentBounceOffset}
        continuousPlacement:true
        dateFontSize:root.custom?root.layout.dateSize:Theme.fontSizeSmall
        dateGap:root.custom?root.layout.dateGap:8
        hoverDateFormat:root.referenceCompact?"ddd, MMM d":"ddd d MMM"
        clockOffsetX:root.custom?root.layout.clockX*(1-root.collapseProgress):0
        clockOffsetY:root.custom?root.layout.clockY*(1-root.collapseProgress):0
        spreadLayout:1-(SettingsService.islandLayout==="balanced"?0:1)*root.collapseProgress
        dateTravel:SettingsService.islandHoverDateFollowBar && SettingsService.clockShowsDate
        dateBelow:true
        datePosition:SettingsService.islandHoverDatePosition
        layoutProgress:root.collapseProgress
        leftPadding:(root.custom?root.layout.leftPadding:28)*(1-root.collapseProgress)+SettingsService.islandPaddingLeft*root.collapseProgress
        rightPadding:(root.custom?root.layout.rightPadding:28)*(1-root.collapseProgress)+SettingsService.islandPaddingRight*root.collapseProgress
        clockScale:(root.expandedClockSize+(root.restingClockSize-root.expandedClockSize)*root.collapseProgress)/root.expandedClockSize
        workspaceMotionActive:root.referenceLayout.active===true
        workspaceMotionOffsets:root.workspaceOffsets
        dateLift:(SettingsService.islandHoverDatePosition==="bottom"?-8:SettingsService.islandHoverDatePosition==="top"?8:0)*(1-root.collapseProgress)
        dateOpacity:barFace.dateTravel?(SettingsService.islandHoverDatePosition==="hidden"?root.collapseProgress:1):1-root.collapseProgress
        // Retain ClockModule's element keys so editor positions morph too.
        y:(parent.height-height)/2
        anchors.left:parent.left;anchors.right:parent.right
        height:Theme.capsuleHeight
        leftVerticalOffset:(root.custom?root.layout.leftY:14)*(1-root.collapseProgress)
        rightVerticalOffset:(root.custom?root.layout.rightY:14)*(1-root.collapseProgress)
        motionOffsets:root.indicatorOffsets
        configuration:root.barSettings
        preview:root.preview
        onSummaryRequested:if(!root.preview)ModuleService.togglePanel("controls")
    }
    HoverHeaderContent {
        objectName:"design:StatusIslandSummary:media"
        kind:SettingsService.islandHoverTopLeft
        compact:root.compact;preview:root.preview
        labelSize:root.custom?root.layout.headerSize:12;iconSize:root.custom?root.layout.headerIconSize:14
        x:root.custom?root.layout.headerLeftX:28;y:root.custom?root.layout.headerY:6;width:Math.max(100,root.width*.31);height:root.custom?root.layout.headerHeight:26
        opacity:Math.max(0,1-root.collapseProgress*3)
    }
    HoverHeaderContent {
        objectName:"design:StatusIslandSummary:status"
        kind:SettingsService.islandHoverTopRight
        alignRight:true;compact:root.compact;preview:root.preview
        labelSize:root.custom?root.layout.headerSize:12;iconSize:root.custom?root.layout.headerIconSize:14
        anchors.right:parent.right;anchors.rightMargin:root.custom?root.layout.headerRightX:28
        y:root.custom?root.layout.headerY:6;width:Math.max(100,root.width*.31);height:root.custom?root.layout.headerHeight:26
        opacity:Math.max(0,1-root.collapseProgress*3)
    }
    Rectangle {
        id:miniPlayer
        visible:root.custom&&root.layout.mediaEnabled&&(!SettingsService.islandHoverMediaAutoHide||MediaService.playing||root.preview)
        x:(parent.width-width)/2+root.layout.mediaX
        y:root.layout.mediaY
        width:Math.min(root.layout.mediaWidth,parent.width-24);height:root.layout.mediaHeight;radius:Math.min(18,height/3)
        opacity:Math.max(0,1-root.collapseProgress*3)
        color:Theme.moduleColour("media","background",Qt.alpha(Theme.surface,.45))
        AntialiasedPreview {
            id:art;x:10;anchors.verticalCenter:parent.verticalCenter;width:Math.min(root.layout.mediaArtSize,parent.height-12);height:width;radius:8
            Image {anchors.fill:parent;source:MediaService.artUrl;fillMode:Image.PreserveAspectCrop;sourceSize:Qt.size(80,80);asynchronous:true}
        }
        Column {
            x:art.x+art.width+10;anchors.verticalCenter:parent.verticalCenter;width:Math.max(20,parent.width-x-(root.layout.mediaControls?96:82));spacing:2
            Text {width:parent.width;text:root.preview?"Now playing":MediaService.title||Tr.t("No media playing");elide:Text.ElideRight;font.family:Theme.fontFamily;font.pixelSize:root.layout.mediaTitleSize;font.weight:Font.DemiBold;color:Theme.moduleColour("media","foreground",Theme.text)}
            Text {width:parent.width;text:root.preview?"Artist":MediaService.artist||"";elide:Text.ElideRight;font.family:Theme.fontFamily;font.pixelSize:root.layout.mediaArtistSize;color:Theme.moduleColour("media","muted",Theme.textMuted)}
        }
        Row {
            visible:!root.layout.mediaControls;anchors.right:parent.right;anchors.rightMargin:14;anchors.verticalCenter:parent.verticalCenter;spacing:3
            opacity:MediaService.playing?.65:.25
            Repeater {model:12;Rectangle {width:2;height:2;radius:1;color:Theme.accent}}
        }
        MouseArea {anchors.fill:parent;enabled:!root.preview&&!root.layout.mediaControls;cursorShape:Qt.ArrowCursor;onClicked:MediaService.toggle()}
        Row {
            visible:root.layout.mediaControls;anchors.right:parent.right;anchors.rightMargin:6;anchors.verticalCenter:parent.verticalCenter;spacing:0
            IconButton {icon:"󰒮";implicitWidth:28;implicitHeight:28;enabled:!root.preview&&MediaService.canPrevious;onClicked:MediaService.previous()}
            IconButton {icon:MediaService.playing?"󰏤":"󰐊";implicitWidth:28;implicitHeight:28;enabled:!root.preview&&MediaService.canToggle;onClicked:MediaService.toggle()}
            IconButton {icon:"󰒭";implicitWidth:28;implicitHeight:28;enabled:!root.preview&&MediaService.canNext;onClicked:MediaService.next()}
        }
    }

}
