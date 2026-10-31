// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   G R O U N D   R O W                                                    │
// │   settings · what one layer is made of, classic, glass or liquid         │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import "../theme"
import "../services"
import "../components"

// One layer's ground, on the page of the layer it paints.
SettingRow {
    id: root

    // The setting that holds it: surfaceStyle, dockGround, desktopGround or
    // terminalGround.
    required property string key

    // Empty, from a profile saved when the layer could follow the bar, is
    // drawn as the bar's, so it reads as the bar's.
    readonly property string stored: SettingsService[root.key] === ""
        ? SettingsService.surfaceStyle : SettingsService[root.key]
    readonly property string value: (root.key === "terminalGround" && root.stored === "blur") || Theme.seeThrough(root.stored) ? root.stored : "classic"

    label: Tr.t("Ground")
    reading: root.value === "blur" ? Tr.t("Adjustable frost with clear text and no refraction") : root.value === "tahoe" ? Tr.t("MacShell refractive liquid glass")
        : root.value === "liquid" ? Tr.t("Hyprglass liquid glass")
        : root.value === "liquid-old" ? Tr.t("Earlier frosted liquid look")
        : root.value === "glass" ? Tr.t("The terminal's glass, over a blur")
        : SettingsService.floatingBarSurface === "grey" ? Tr.t("Solid dark grey") : Tr.t("Solid black")

    SegmentedControl {
        options: root.key === "terminalGround" ? [
                {id:"classic",label:Tr.t("Black/grey")},
                {id:"glass",label:Tr.t("Glass")},
                {id:"blur",label:Tr.t("Blur")},
                {id:"tahoe",label:Tr.t("MacShell")},
                {id:"liquid",label:Tr.t("Liquid Glass")}
            ] : root.key === "surfaceStyle"
            ? [
                { id: "classic", label: Tr.t("Black/grey") },
                { id: "glass", label: Tr.t("Glass") },
                { id: "tahoe", label: Tr.t("MacShell") },
                { id: "liquid", label: Tr.t("Liquid Glass") },
                { id: "liquid-old", label: Tr.t("Liquid Glass (Old)") }
            ]
            : [
                { id: "classic", label: Tr.t("Black/grey") },
                { id: "glass", label: Tr.t("Glass") },
                { id: "tahoe", label: Tr.t("MacShell") },
                { id: "liquid", label: Tr.t("Liquid Glass") }
            ]
        current: root.value
        onSelected: id => { if(root.key === "surfaceStyle")BarColourService.apply({surfaceStyle:id});else {SettingsService.set(root.key,id);if(root.key === "terminalGround")SettingsService.set("macGlassTerminal",id === "tahoe")} }
    }
}
