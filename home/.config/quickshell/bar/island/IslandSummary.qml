import QtQuick
import "../../services"
Loader {
    id:root
    property real collapseProgress:0
    property real contentBounceOffset:0
    property var referenceLayout:({})
    sourceComponent:SettingsService.islandHoverDesign==="classic"?classic:banner
    Component {id:classic;ClassicIslandSummary {}}
    Component {id:banner;StatusIslandSummary {compact:SettingsService.islandHoverDesign==="compact";collapseProgress:root.collapseProgress;contentBounceOffset:root.contentBounceOffset;referenceLayout:root.referenceLayout}}
}
