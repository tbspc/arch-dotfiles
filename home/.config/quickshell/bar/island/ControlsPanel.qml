import QtQuick
import "../../services"
Item {
    id:root
    signal closed()
    signal panelRequested(string panel)
    signal settingsRequested()
    Loader {anchors.fill:parent;sourceComponent:SettingsService.centreDesign==="reference"?reference:original}
    Component{id:original;ClassicControlsPanel{onClosed:root.closed();onPanelRequested:panel=>root.panelRequested(panel);onSettingsRequested:root.settingsRequested()}}
    Component{id:reference;ReferenceControlsPanel{onClosed:root.closed();onPanelRequested:panel=>root.panelRequested(panel);onSettingsRequested:root.settingsRequested()}}
}
