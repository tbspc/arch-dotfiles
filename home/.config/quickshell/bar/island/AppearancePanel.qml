import QtQuick
import "../../services"

FocusScope {
    id:root
    signal closed()
    signal panelRequested(string panel)
    property string page:"wallpaper"
    readonly property string design:root.page==="palette"?SettingsService.themePickerDesign:SettingsService.wallpaperPickerDesign
    function navigationStatus():var{return content.item?.navigationStatus()||{}}
    function browse(direction:string):void{content.item?.browse?.(direction)}
    Loader {
        id:content;anchors.fill:parent
        sourceComponent:root.design==="gallery"?gallery:root.design==="reference"?reference:classic
        onLoaded:item.forceActiveFocus()
    }
    Connections {target:content.item
        function onClosed():void{root.closed()}
        function onPanelRequested(panel:string):void{root.panelRequested(panel)}
    }
    Component{id:classic;ClassicAppearancePanel{page:root.page}}
    Component{id:reference;ReferenceAppearancePanel{page:root.page}}
    Component{id:gallery;ReferenceAppearancePanel{page:root.page;compact:true}}
}
