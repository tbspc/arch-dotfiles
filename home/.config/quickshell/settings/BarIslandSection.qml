import QtQuick
import "../components"
import QtQuick.Layouts
SettingsSection {
    id:root
    property string tab:"style"
    readonly property bool barTab:["style","workspaces"].includes(root.tab)
    readonly property string islandTab:root.tab === "islandworkspaces" ? "workspaces" : root.tab
    Loader {
        id:content
        Layout.fillWidth:true
        sourceComponent:root.barTab?bar:island
        onLoaded:if(item)item.tab=Qt.binding(()=>root.barTab?root.tab:root.islandTab)
    }
    Component { id:bar;BarSection {} }
    Component { id:island;IslandSection {} }
}
