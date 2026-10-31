import QtQuick
import QtQuick.Layouts
import "../services"
import "../theme"
import "../components"
ColumnLayout {
    id:root
    property string app:"nautilus"
    readonly property string applicationName:root.app==="settings"?Tr.t("Settings"):Tr.t("Files (Nautilus)")
    readonly property bool enabledBlur:SettingsService[root.app+"Blur"]
    Layout.fillWidth:true
    spacing:12
    SettingGroup {
        title:root.applicationName+Tr.t(" blur")
        note:Tr.t("Independent frost and transparency controls. Replaces refraction for this app while enabled.")
        SettingRow {label:Tr.t("Use Blur");ToggleSwitch {checked:root.enabledBlur;onToggled:value=>SettingsService.set(root.app+"Blur",value)}}
    }
    Loader {
        active:root.enabledBlur;visible:active;Layout.fillWidth:true
        sourceComponent:Component {TerminalBlurControls {settingKey:root.app+"Frost";applicationName:root.applicationName}}
    }
}
