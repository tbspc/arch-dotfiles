import QtQuick
import QtQuick.Layouts
import "../components"
SettingsSection {
    id:root
    property string tab:"presets"
    property real viewportTop:0
    property real viewportHeight:800
    readonly property var presets:content.item?.presets||[]
    readonly property int previewColumns:content.item?.previewColumns||0
    function previewStats():var {return content.item?.previewStats?.()||{}}
    Loader {
        id:content
        Layout.fillWidth:true
        sourceComponent:root.tab==="opening"?opening:root.tab==="customize"?customize:root.tab==="hover"?hover:presetPage
    }
    Component {id:presetPage;PresetBrowser {kind:"shellmotion";inlineMotionControls:false;viewportTop:root.viewportTop;viewportHeight:root.viewportHeight}}
    Component {id:customize;ShellMotionControls {}}
    Component {id:opening;ModuleAnimationSettings {selected:"bar"}}
    Component {id:hover;HoverTimingSettings {}}
}
