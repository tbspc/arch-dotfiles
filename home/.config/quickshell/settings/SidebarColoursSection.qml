import QtQuick
import Quickshell
import "../components"
import "../services"
import "../theme"
SettingsSection {
    id:root
    property string editing:"icons"
    TabStrip {tabs:[{id:"icons",label:Tr.t("Icons")},{id:"text",label:Tr.t("Text")}];current:root.editing;onPicked:id=>root.editing=id}
    SettingGroup {
        visible:root.editing==="icons"
        title:Tr.t("Sidebar icon colours")
        note:Tr.t("These colours affect the icons only.")
        SettingsColourRow {label:Tr.t("Overview");sidebar:true;colourId:"overview";fallback:Theme.accentIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Profile");sidebar:true;colourId:"you";fallback:Theme.accentIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Presets");sidebar:true;colourId:"presets";fallback:Theme.accentIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Personalization");sidebar:true;colourId:"personalization";fallback:Theme.accentIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Bar & dock");sidebar:true;colourId:"bar";fallback:Theme.accentIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Apps & modules");sidebar:true;colourId:"apps";fallback:Theme.accentIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Windows & displays");sidebar:true;colourId:"desktop";fallback:Theme.accentIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Input & shortcuts");sidebar:true;colourId:"input";fallback:Theme.accentIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Lock & session");sidebar:true;colourId:"session";fallback:Theme.accentIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("System");sidebar:true;colourId:"system";fallback:Theme.accentIn(QsWindow.window)}
    }
    SettingGroup {
        visible:root.editing==="text"
        title:Tr.t("Sidebar text colours")
        note:Tr.t("Choose a fixed hex colour or wallpaper accent independently of the icons.")
        SettingsColourRow {label:Tr.t("Overview");sidebar:true;sidebarText:true;colourId:"overview";fallback:Theme.textIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Profile");sidebar:true;sidebarText:true;colourId:"you";fallback:Theme.textIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Presets");sidebar:true;sidebarText:true;colourId:"presets";fallback:Theme.textIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Personalization");sidebar:true;sidebarText:true;colourId:"personalization";fallback:Theme.textIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Bar & dock");sidebar:true;sidebarText:true;colourId:"bar";fallback:Theme.textIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Apps & modules");sidebar:true;sidebarText:true;colourId:"apps";fallback:Theme.textIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Windows & displays");sidebar:true;sidebarText:true;colourId:"desktop";fallback:Theme.textIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Input & shortcuts");sidebar:true;sidebarText:true;colourId:"input";fallback:Theme.textIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("Lock & session");sidebar:true;sidebarText:true;colourId:"session";fallback:Theme.textIn(QsWindow.window)}
        SettingsColourRow {label:Tr.t("System");sidebar:true;sidebarText:true;colourId:"system";fallback:Theme.textIn(QsWindow.window)}
    }
}
