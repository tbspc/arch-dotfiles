import "../" as Config
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../services"
import "../theme"

SettingsSection {
    id: root
    property string tab: ""
    property bool inlineMotionControls:true
    property real viewportTop:0
    property real viewportHeight:800
    property string kind: "bar"
    property string query: ""
    property string category: "all"
    property string sourceFilter: "all"
    property string subcategory: "all"
    property string moduleId: "notes"
    property string name: ""
    property string deleting: ""
    property bool saveExpanded: false
    readonly property int previewColumns: presetGrid.columns
    property string message: ""
    readonly property var service: kind === "bar" ? IslandPresetService : kind === "launcher" ? LauncherPresetService
        : kind === "lockscreen" ? Config.LockDesignPresetService : kind === "designs" ? SettingsDesignService : kind === "lockmotion" ? LockAnimationPresetService
        : kind === "setup" ? SetupPresetService : kind === "macglass" ? MacGlassPresetService : null
    readonly property bool canSave: !["windowmotion", "barcolour"].includes(kind)
    readonly property var library: {
        if (kind === "barcolour") return BarColourService.designs
        if (kind === "modules") return ModulePresetService.list(moduleId)
        if (kind === "shellmotion") return SettingsService.savedShellMotionPresets.map(p=>({id:p.id,name:p.name,description:Tr.t("Your saved animation configuration"),values:p,editable:true,source:"saved"})).concat(Theme.motionPresets.map(p => ({id:p.id, name:p.label, description:p.group==="reference"?Tr.t("Traced video paths · moving indicators · separate panel timings"):p.group==="fast"?(p.settings.shellExpandDuration+" ms · "+Tr.t("immediate resize and short hover delays")):"", values:p, editable:false, source:"built-in"})))
        if (kind === "windowmotion") return Motion.presets.map(p => ({id:p.id, name:p.label, description:p.note, values:p, editable:false, source:"built-in"}))
        return (service?.saved || []).map(p => Object.assign({}, p, {editable:true, source:"saved"}))
            .concat((service?.designs || []).map(p => Object.assign({}, p, {editable:["bar","launcher","lockmotion"].includes(kind), source:"built-in"})))
    }
    readonly property var categories: kind === "bar" ? [{id:"all",label:Tr.t("All")},{id:"floating",label:Tr.t("Floating")},{id:"notched",label:Tr.t("Notched")},{id:"chips",label:Tr.t("Chips")}]
        : kind === "launcher" ? [{id:"all",label:Tr.t("All")}].concat(LauncherPresetService.categories.map(c=>({id:c.id,label:c.name}))) : kind === "shellmotion" ? [{id:"all",label:Tr.t("All")},{id:"reference",label:Tr.t("Reference")},{id:"fast",label:Tr.t("Fast")},{id:"pace",label:Tr.t("Pace")},{id:"bounce",label:Tr.t("Bounce")},{id:"fade",label:Tr.t("Fade")}]
        : kind === "windowmotion" ? [{id:"all",label:Tr.t("All")},{id:"original",label:Tr.t("Original")},{id:"calm",label:Tr.t("Calm & spring")},{id:"fade",label:Tr.t("Fades")}] : []
    readonly property var styles: ["bar","launcher"].includes(kind) ? [{id:"all",label:Tr.t("All styles")}].concat((kind==="bar"?IslandPresetService.subcategories:LauncherPresetService.subcategories).map(c=>({id:c.id,label:c.name}))) : []
    function categoryFor(p:var):string {
        if(kind==="bar")return IslandPresetService.categoryOf(p.values)
        if(kind==="launcher")return LauncherPresetService.categoryOf(p.values)
        if(kind==="windowmotion")return p.values.group || "original"
        if(kind==="shellmotion")return p.values.group==="reference"?"reference":p.values.group==="fast"?"fast":p.values.curve.startsWith("Fade")?"fade":["OutBounce","OutElastic","InOutBack"].includes(p.values.curve)?"bounce":"pace"
        return "all"
    }
    readonly property var presets: library.filter(p => {
        const search = [p.name, p.description || ""].join(" ").toLowerCase().includes(query.trim().toLowerCase())
        const group = category === "all" || root.categoryFor(p) === category
        const style = subcategory === "all" || (kind === "bar" ? IslandPresetService.subcategoryOf(p) : kind === "launcher" ? LauncherPresetService.subcategoryOf(p.values) : "all") === subcategory
        return search && group && style && (sourceFilter === "all" || p.source === sourceFilter)
    })
    onKindChanged:{query="";category="all";subcategory="all";sourceFilter="all";name="";deleting="";message=""}
    function apply(p: var): void {
        if (kind === "barcolour") BarColourService.apply(p.values)
        else if (kind === "modules") ModulePresetService.apply(moduleId,p.values)
        else if (kind === "shellmotion") SettingsService.applyShellMotionPreset(p.values)
        else if (kind === "windowmotion") SettingsService.set("animationPreset",p.id)
        else service.apply(p.values)
        message = Tr.t("Applied") + " · " + p.name
    }
    function saveCurrent(): void {
        if (kind === "modules") ModulePresetService.save(moduleId,name)
        else if(kind==="shellmotion")SettingsService.saveShellMotionPreset(name)
        else service.save(name)
        name = ""; message = Tr.t("Preset saved")
    }
    function update(p: var): void {
        if (kind === "modules") ModulePresetService.update(moduleId,p.id)
        else if(kind==="shellmotion")SettingsService.updateShellMotionPreset(p.id)
        else service.update(p.id)
        message = Tr.t("Updated") + " · " + p.name
    }
    function remove(p: var): void {
        if (deleting !== p.id) { deleting = p.id; return }
        if (kind === "modules") ModulePresetService.remove(moduleId,p.id)
        else if(kind==="shellmotion")SettingsService.removeShellMotionPreset(p.id)
        else service.remove(p.id)
        deleting = ""; message = Tr.t("Preset deleted")
    }
    function sameValue(a:var,b:var):bool {
        if(a===b)return true
        if(a===null||b===null||typeof a!=="object"||typeof b!=="object")return false
        const left=Object.keys(a).sort(),right=Object.keys(b).sort()
        return left.length===right.length&&left.every((key,i)=>key===right[i]&&root.sameValue(a[key],b[key]))
    }
    function matches(p: var): bool {
        if (kind === "barcolour") return BarColourService.matches(p.values)
        if (kind === "shellmotion") {
            const base=!SettingsService.gameMode&&SettingsService.motionScale===p.values.scale&&SettingsService.motionCurve===p.values.curve
            if(!base)return false
            if(p.values.settings)return Object.entries(p.values.settings).every(([key,value])=>root.sameValue(SettingsService[key],value))&&(!p.values.moduleOverrides||root.sameValue(SettingsService.moduleAnimations,p.values.moduleOverrides))
            return !Theme.motionPresets.some(entry=>entry.settings&&entry.scale===SettingsService.motionScale&&entry.curve===SettingsService.motionCurve&&Object.entries(entry.settings).every(([key,value])=>root.sameValue(SettingsService[key],value)))
        }
        if (kind === "windowmotion") return SettingsService.animationPreset === p.id
        if (["bar","launcher","lockmotion","macglass","lockscreen"].includes(kind)) return service.matches(p.values)
        if (kind === "designs") return Object.keys(p.values).every(k=>SettingsDesignService.style[k]===p.values[k])
        return false
    }
    function previewStats():var {
        let loaded=0
        for(let i=0;i<presetCards.count;i++)if(presetCards.itemAt(i)?.previewLoaded)loaded++
        return {total:presetCards.count,loaded:loaded}
    }
    Component.onCompleted: if (kind === "modules") ModulePresetService.seed()
    ColumnLayout {
        Layout.fillWidth:true;spacing:10
        RowLayout {
            Layout.fillWidth:true;spacing:10
            Rectangle {
                Layout.fillWidth:true;implicitHeight:40;radius:11
                color:Theme.surfaceIn(QsWindow.window);border.width:1;border.color:find.activeFocus?Theme.accentIn(QsWindow.window):Theme.borderIn(QsWindow.window)
                TextInput {
                    id:find
                    anchors.fill:parent;anchors.leftMargin:13;anchors.rightMargin:13
                    verticalAlignment:TextInput.AlignVCenter;text:root.query;onTextEdited:root.query=text
                    font.family:Theme.fontIn(QsWindow.window);font.pixelSize:13;color:Theme.textIn(QsWindow.window);selectByMouse:true;clip:true
                    selectionColor:Theme.accentIn(QsWindow.window)
                    Text { anchors.verticalCenter:parent.verticalCenter;visible:!parent.text;text:Tr.t("Search presets…");font:parent.font;color:Theme.mutedIn(QsWindow.window) }
                }
            }
            ThemedComboBox { visible:root.kind === "modules";Layout.preferredWidth:220;model:ModulePresetService.modules;textRole:"name";currentIndex:Math.max(0,model.findIndex(m=>m.id===root.moduleId));onActivated:index=>root.moduleId=model[index].id }
            PillButton { visible:root.canSave;text:Tr.t("Save current");active:root.saveExpanded;onClicked:root.saveExpanded=!root.saveExpanded }
        }
        RowLayout {
            Layout.fillWidth:true;visible:root.categories.length>0 || (root.canSave && root.kind!=="modules")
            Flow { Layout.fillWidth:true;spacing:6
                Repeater { model:root.categories;PillButton { required property var modelData;text:modelData.label;active:root.category===modelData.id;onClicked:root.category=modelData.id } }
            }
            SegmentedControl { visible:root.canSave && root.kind!=="modules";options:[{id:"all",label:Tr.t("All")},{id:"saved",label:Tr.t("Saved")},{id:"built-in",label:Tr.t("Built-in")}];current:root.sourceFilter;onSelected:id=>root.sourceFilter=id }
        }
        Flow { Layout.fillWidth:true;visible:root.styles.length>0;spacing:6
            Repeater { model:root.styles;PillButton { required property var modelData;text:modelData.label;active:root.subcategory===modelData.id;onClicked:root.subcategory=modelData.id } }
        }
        RowLayout {
            Layout.fillWidth:true;spacing:8
            Text { Layout.fillWidth:true;text:root.message || Tr.t("%1 presets").arg(root.presets.length);elide:Text.ElideRight;color:Theme.mutedIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:12 }
            PillButton { visible:root.query!=="" || root.category!=="all" || root.subcategory!=="all" || root.sourceFilter!=="all";text:Tr.t("Clear filters");onClicked:{root.query="";root.category="all";root.subcategory="all";root.sourceFilter="all"} }
            PillButton { visible:["bar","launcher","setup"].includes(root.kind);text:Tr.t("Open carousel");onClicked:ModuleService.requestPanel(root.kind==="bar"?"barpresets":root.kind==="launcher"?"launcherpresets":"setuppresets") }
            PillButton { visible:["bar","launcher","lockmotion"].includes(root.kind);text:Tr.t("Restore built-ins");onClicked:root.kind==="bar"?IslandPresetService.restoreDesigns():root.service.restore() }
        }
    }
    MacGlassControls {visible:root.kind==="barcolour"}
    LibraryModeSettings { visible:root.kind === "setup" }
    WindowMotionControls {visible:root.kind === "windowmotion"}
    ShellMotionControls {visible:root.kind === "shellmotion"&&root.inlineMotionControls}
    SettingGroup {
        visible:root.kind === "barcolour"
        title:Tr.t("Black/grey")
        note:Tr.t("This material applies to the bar, module panels, dock and desktop widgets.")
        SettingRow { label:Tr.t("Solid colour");SegmentedControl { options:[{id:"black",label:Tr.t("Black")},{id:"grey",label:Tr.t("Grey")}];current:SettingsService.floatingBarSurface;onSelected:id=>BarColourService.apply({surfaceStyle:"classic",floatingBarSurface:id}) } }
    }
    SettingGroup {
        visible:root.kind === "designs"
        SettingRow { label:Tr.t("Use wallpaper theme accent");reading:Tr.t("The Arch logo always follows your wallpaper colours.")
            ToggleSwitch { checked:SettingsDesignService.style.useThemeAccent!==false;onToggled:checked=>SettingsDesignService.apply(Object.assign({},SettingsDesignService.style,{useThemeAccent:checked})) }
        }
    }
    SettingGroup {
        visible:root.kind === "shellmotion"
        SettingRow { label:Tr.t("Game mode");reading:Tr.t("Temporarily disables all shell animations.")
            ToggleSwitch { checked:SettingsService.gameMode;onToggled:checked=>SettingsService.set("gameMode",checked) }
        }
    }
    SettingGroup {
        visible:root.canSave && root.saveExpanded
        title:Tr.t("Save your current configuration")
        SettingField { label:Tr.t("Preset name");placeholder:Tr.t("My preset");value:root.name;onEdited:value=>root.name=value }
        SettingRow { label:Tr.t("Keep this configuration for later");PillButton { text:Tr.t("Save preset");active:true;onClicked:{root.saveCurrent();root.saveExpanded=false} } }
    }
    GridLayout {
        id:presetGrid
        Layout.fillWidth:true
        columns:width >= 700 ? 4 : width >= 500 ? 3 : width >= 340 ? 2 : 1
        columnSpacing:12;rowSpacing:12
        Repeater {
            id:presetCards
            model:root.presets
            Rectangle {
                id:card
                required property var modelData
                readonly property bool previewLoaded:previewLoader.status===Loader.Ready
                readonly property bool inViewport:card.y+presetGrid.y+card.height>=root.viewportTop-120 && card.y+presetGrid.y<=root.viewportTop+root.viewportHeight+120
                readonly property bool chosen:inViewport && root.matches(modelData)
                Layout.fillWidth:true;Layout.preferredWidth:1;Layout.alignment:Qt.AlignTop
                implicitHeight:body.implicitHeight+24;radius:16
                color:SettingsDesignService.style.cardBackground || Theme.surfaceIn(QsWindow.window)
                border.width:1;border.color:chosen?Theme.accentIn(QsWindow.window):Theme.borderIn(QsWindow.window)
                ColumnLayout {
                    id:body
                    anchors.left:parent.left;anchors.right:parent.right;anchors.top:parent.top;anchors.margins:12;spacing:10
                    Rectangle {
                        Layout.fillWidth:true;Layout.preferredHeight:116;radius:10;color:SettingsDesignService.style.fieldBackground || Theme.surfaceIn(QsWindow.window);clip:true
                        Loader {
                            id:previewLoader
                            anchors.fill:parent;anchors.margins:4
                            active:card.inViewport
                            asynchronous:false
                            sourceComponent:PresetVisual { kind:root.kind;moduleId:root.moduleId;values:card.modelData.values;animate:card.inViewport }
                        }
                        HoverHandler { id:previewHover }
                    }
                    Text { Layout.fillWidth:true;text:card.modelData.name;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:14;font.weight:Font.DemiBold;color:Theme.textIn(QsWindow.window);elide:Text.ElideRight }
                    Text { Layout.fillWidth:true;text:card.chosen?Tr.t("In use"):card.modelData.source === "saved"?Tr.t("Saved preset"):Tr.t("Built-in");font.family:Theme.fontIn(QsWindow.window);font.pixelSize:11;color:card.chosen?Theme.accentIn(QsWindow.window):Theme.mutedIn(QsWindow.window) }
                    Text { Layout.fillWidth:true;text:card.modelData.description || "";visible:text!=="";font.family:Theme.fontIn(QsWindow.window);font.pixelSize:11;color:Theme.mutedIn(QsWindow.window);wrapMode:Text.WordWrap;maximumLineCount:2;elide:Text.ElideRight }
                    Flow {
                        Layout.fillWidth:true;spacing:5
                        PillButton { text:Tr.t("Apply");active:card.chosen;onClicked:root.apply(card.modelData) }
                        PillButton { visible:card.modelData.editable === true;text:Tr.t("Update");onClicked:root.update(card.modelData) }
                        PillButton { visible:card.modelData.editable === true;text:root.deleting===card.modelData.id?Tr.t("Delete?"):Tr.t("Delete");onClicked:root.remove(card.modelData) }
                    }
                }
            }
        }
    }
    Text { visible:root.presets.length===0; text:Tr.t("No presets match these filters."); color:Theme.mutedIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:14 }
}
