import QtQuick
import "../services"
import "../theme"
import "../components"
SettingGroup {
    title:Tr.t("Workspace colours")
    SettingsColourRow {label:Tr.t("Active workspace");colourId:"workspaces";role:"active";fallback:Theme.accent}
    SettingsColourRow {label:Tr.t("Inactive workspace");colourId:"workspaces";role:"inactive";fallback:Theme.indicatorDim}
    SettingsColourRow {label:Tr.t("Workspace with windows");colourId:"workspaces";role:"occupied";fallback:Theme.accent}
}
