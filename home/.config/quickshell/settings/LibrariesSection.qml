import QtQuick
import QtQuick.Layouts
import "../services"
import "../components"
import "../theme"
SettingsSection {
    property string tab:""
    LibraryModeSettings {}
    SettingGroup {
        title:Tr.t("Document library")
        note:Tr.t("Arrow keys move between documents with an animated selection and scrolling.")
        SettingRow { label:Tr.t("Visible rows");reading:Tr.t("More rows grow the panel and keep previews visible. It scrolls when the screen is full.")
            ThemedComboBox { model:[1,2,3,4,5,6];currentIndex:Math.max(0,model.indexOf(SettingsService.documentLibraryRows));onActivated:SettingsService.set("documentLibraryRows",model[currentIndex]) }
        }
        SettingRow { label:Tr.t("Selection animation")
            ThemedComboBox { model:[{id:"slide",name:Tr.t("Smooth slide")},{id:"fade",name:Tr.t("Fade")},{id:"bounce",name:Tr.t("Soft bounce")},{id:"none",name:Tr.t("Instant")}];textRole:"name";currentIndex:Math.max(0,model.findIndex(e=>e.id===SettingsService.documentLibraryMotion));onActivated:SettingsService.set("documentLibraryMotion",model[currentIndex].id) }
        }
        SettingSlider { label:Tr.t("Animation duration");from:60;to:500;unit:" ms";value:SettingsService.documentLibraryMotionDuration;onMoved:value=>SettingsService.set("documentLibraryMotionDuration",Math.round(value)) }
    }
}
