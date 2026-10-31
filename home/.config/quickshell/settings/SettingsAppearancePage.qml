import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../services"
import "../components"

SettingsSection {
    id:root
    property string tab:"colours"
    property bool expandedColours:false
    Loader {Layout.fillWidth:true;active:root.tab==="sidebarcolours";visible:active;sourceComponent:SidebarColoursSection {}}
    readonly property var design:SettingsDesignService.style
    readonly property bool custom:SettingsDesignService.forma
    function set(key,value){SettingsDesignService.set(key,value)}
    Component.onCompleted:FontService.load()
    component StyleSlider:SettingSlider {
        required property string key
        value:root.design[key]??0
        onMoved:value=>root.set(key,Math.round(value))
    }
    component StyleToggle:SettingRow {
        id:styleToggle
        required property string key
        ToggleSwitch {checked:root.design[styleToggle.key]!==false;onToggled:value=>root.set(styleToggle.key,value)}
    }
    component ColourRow:SettingRow {
        id:colourRow
        required property string key
        Row {
            spacing:8
            Rectangle {width:30;height:34;radius:7;color:root.design[colourRow.key]||"#000000";border.width:1;border.color:Theme.borderIn(QsWindow.window)}
            Rectangle {
                width:150;height:34;radius:8;color:Theme.surfaceIn(QsWindow.window);border.width:1;border.color:Theme.borderIn(QsWindow.window)
                TextInput {
                    anchors.fill:parent;anchors.leftMargin:10;anchors.rightMargin:10
                    verticalAlignment:TextInput.AlignVCenter;selectByMouse:true
                    text:root.design[colourRow.key]||"";font.family:Theme.fontMono;font.pixelSize:12;color:Theme.textIn(QsWindow.window)
                    onEditingFinished:{if(!/^#[0-9a-fA-F]{6}$/.test(text))return;if(colourRow.key==="accentColor"){root.set("useThemeAccent",false);root.set("accentColor",text)}else SettingsDesignService.setColour(colourRow.key,text)}
                }
            }
        }
    }
    SettingGroup {
        visible:!root.custom
        title:Tr.t("New settings design")
        SettingRow {label:Tr.t("Use the new customizable interface");PillButton {text:Tr.t("Use design");active:true;onClicked:SettingsDesignService.useForma()}}
    }
    RowLayout {
        visible:root.tab!=="sidebarcolours"
        Layout.fillWidth:true;spacing:26
        ColumnLayout {
            Layout.fillWidth:true;Layout.preferredWidth:1;Layout.alignment:Qt.AlignTop;spacing:20
            AppBlurControls {visible:root.tab==="colours";app:"settings"}
            MacGlassControls {visible:root.tab==="colours"}
            SettingGroup {
                visible:root.tab==="colours"
                title:Tr.t("Colour theme")
                note:Tr.t("Set the mood for your settings.")
                SettingBlock {
                    GridLayout {Layout.fillWidth:true;columns:3;columnSpacing:10
                        Repeater {model:[{id:"light",name:Tr.t("Light")},{id:"dark",name:Tr.t("Dark")},{id:"black",name:Tr.t("Black")}]
                            PreviewTile {
                                id:modeTile
                                required property var modelData
                                stageHeight:106;caption:modelData.name;selected:(root.design.colourMode||"dark")===modelData.id
                                onPicked:{if(!root.custom)SettingsDesignService.useForma();root.set("colourMode",modelData.id)}
                                SettingsMiniature {anchors.fill:parent;anchors.margins:6;colours:SettingsDesignService.modern?SettingsDesignService.modernPalette(modeTile.modelData.id,root.design.surfaceTone):SettingsDesignService.paletteFor(modeTile.modelData.id,root.design.surfaceTone);accent:Theme.accentIn(QsWindow.window)}
                            }
                        }
                    }
                }
            }
            SettingGroup {
                visible:root.tab==="colours"
                title:Tr.t("Interface colour")
                note:Tr.t("Colour the page, sidebar and cards independently of the button accent. Bar grey matches your bar’s #141414.")
                SettingBlock {
                    Flow {Layout.fillWidth:true;spacing:8
                        Repeater {model:SettingsDesignService.surfaceTones
                            Rectangle {
                                id:toneButton
                                required property var modelData
                                readonly property bool selected:(root.design.surfaceTone||"forest")===modelData.id
                                width:toneRow.implicitWidth+20;height:34;radius:8
                                color:selected?Theme.surfaceHoverIn(QsWindow.window):Theme.surfaceIn(QsWindow.window)
                                border.width:1;border.color:selected?Theme.accentIn(QsWindow.window):Theme.borderIn(QsWindow.window)
                                Row {id:toneRow;anchors.centerIn:parent;spacing:8
                                    Rectangle {width:14;height:14;radius:7;color:toneButton.modelData.swatch;border.width:1;border.color:Theme.mutedIn(QsWindow.window)}
                                    Text {text:Tr.t(toneButton.modelData.name);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:12;color:Theme.textIn(QsWindow.window)}
                                }
                                HoverHandler {cursorShape:Qt.PointingHandCursor}
                                TapHandler {onTapped:{if(!root.custom)SettingsDesignService.useForma();root.set("surfaceTone",toneButton.modelData.id)}}
                            }
                        }
                    }
                }
            }
            SettingGroup {
                visible:root.tab==="colours"
                title:Tr.t("A touch of colour")
                note:Tr.t("Your accent for buttons, selections and highlights. The Arch symbol always follows the wallpaper.")
                SettingBlock {
                    Flow {Layout.fillWidth:true;spacing:10
                        Repeater {model:SettingsDesignService.accents
                            Rectangle {
                                id:swatch
                                required property var modelData
                                width:32;height:32;radius:16;color:modelData.colour
                                border.width:!root.design.useThemeAccent && String(root.design.accentColor||"").toLowerCase()===modelData.colour.toLowerCase()?3:0
                                border.color:Theme.textIn(QsWindow.window)
                                Text {anchors.centerIn:parent;visible:swatch.border.width>0;text:"✓";font.pixelSize:17;color:"#142117"}
                                HoverHandler {cursorShape:Qt.PointingHandCursor}
                                TapHandler {onTapped:{root.set("useThemeAccent",false);root.set("accentColor",swatch.modelData.colour)}}
                            }
                        }
                        PillButton {text:Tr.t("Wallpaper");active:root.design.useThemeAccent!==false;onClicked:root.set("useThemeAccent",true)}
                    }
                }
                ColourRow {key:"accentColor";label:Tr.t("Custom accent")}
                SettingRow {label:Tr.t("Fine-tune every surface colour");PillButton {text:root.expandedColours?Tr.t("Hide"):Tr.t("Customize");onClicked:root.expandedColours=!root.expandedColours}}
                ColourRow {visible:root.expandedColours;key:"background";label:Tr.t("Page background")}
                ColourRow {visible:root.expandedColours;key:"sidebarBackground";label:Tr.t("Sidebar")}
                ColourRow {visible:root.expandedColours;key:"cardBackground";label:Tr.t("Cards")}
                ColourRow {visible:root.expandedColours;key:"fieldBackground";label:Tr.t("Fields and buttons")}
                ColourRow {visible:root.expandedColours;key:"hoverColor";label:Tr.t("Hover surface")}
                ColourRow {visible:root.expandedColours;key:"borderColor";label:Tr.t("Borders")}
                ColourRow {visible:root.expandedColours;key:"textColor";label:Tr.t("Main text")}
                ColourRow {visible:root.expandedColours;key:"mutedColor";label:Tr.t("Secondary text")}
                SettingRow {visible:root.expandedColours;label:Tr.t("Restore this theme’s colours");PillButton {text:Tr.t("Reset colours");onClicked:SettingsDesignService.clearColours()}}
            }
            SettingGroup {
                visible:root.tab==="colours" || root.tab==="layout"
                title:Tr.t("Layout & typography")
                note:Tr.t("Find your balance of space and focus.")
                SettingRow {label:Tr.t("Interface density")
                    SegmentedControl {options:[{id:"comfortable",label:Tr.t("Comfortable")},{id:"compact",label:Tr.t("Compact")}];current:root.design.rowHeight<60?"compact":"comfortable";onSelected:id=>{root.set("rowHeight",id==="compact"?52:68);root.set("rowPadding",id==="compact"?8:13);root.set("controlHeight",id==="compact"?32:36)}}
                }
                StyleSlider {key:"textScale";label:Tr.t("Text scale");from:85;to:145;unit:"%"}
                SettingBlock {
                    Rectangle {Layout.fillWidth:true;implicitHeight:64;radius:10;color:Theme.surfaceIn(QsWindow.window)
                        Column {anchors.fill:parent;anchors.margins:12;spacing:5
                            Text {text:Tr.t("Good work starts with a clear view.");font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.textSizeIn(QsWindow.window,14);color:Theme.textIn(QsWindow.window)}
                            Text {text:"Aa Bb Cc  0123456789";font.family:Theme.fontIn(QsWindow.window);font.pixelSize:11;color:Theme.mutedIn(QsWindow.window)}
                        }
                    }
                }
            }
            SettingGroup {
                visible:root.tab==="layout";title:Tr.t("Window & page")
                SettingRow {label:Tr.t("Open Settings as");SegmentedControl {options:[{id:"floating",label:Tr.t("Floating")},{id:"tiled",label:Tr.t("Window arrangement")}];current:SettingsService.settingsWindowMode;onSelected:id=>SettingsService.set("settingsWindowMode",id)}}
                SettingSlider {label:Tr.t("Settings scrolling speed");from:25;to:400;unit:"%";value:SettingsService.settingsScrollSpeed;onMoved:value=>SettingsService.set("settingsScrollSpeed",Math.round(value))}
                StyleSlider {key:"windowWidth";label:Tr.t("Window width");from:980;to:1680;unit:" px"}
                StyleSlider {key:"windowHeight";label:Tr.t("Window height");from:680;to:1100;unit:" px"}
                StyleSlider {key:"contentMargin";label:Tr.t("Page margins");from:16;to:60;unit:" px"}
                StyleSlider {key:"gap";label:Tr.t("Page spacing");from:8;to:40;unit:" px"}
                StyleSlider {key:"groupGap";label:Tr.t("Space between cards");from:8;to:42;unit:" px"}
                StyleSlider {key:"cardRadius";label:Tr.t("Card rounding");from:0;to:30;unit:" px"}
                StyleSlider {key:"cardPadding";label:Tr.t("Card padding");from:8;to:30;unit:" px"}
                StyleSlider {key:"borderWidth";label:Tr.t("Card border width");from:0;to:3;unit:" px"}
            }
            SettingGroup {
                visible:root.tab==="layout";title:Tr.t("Sidebar")
                StyleSlider {key:"sidebarWidth";label:Tr.t("Sidebar width");from:190;to:340;unit:" px"}
                StyleSlider {key:"sidebarPadding";label:Tr.t("Sidebar padding");from:6;to:22;unit:" px"}
                StyleSlider {key:"navRowHeight";label:Tr.t("Navigation row height");from:32;to:58;unit:" px"}
                StyleSlider {key:"sidebarSpacing";label:Tr.t("Sidebar spacing");from:4;to:20;unit:" px"}
                StyleSlider {key:"navRadius";label:Tr.t("Selection rounding");from:0;to:20;unit:" px"}
                StyleSlider {key:"sidebarIconSize";label:Tr.t("Icon size");from:12;to:26;unit:" px"}
            }
            SettingGroup {
                visible:root.tab==="type";title:Tr.t("Typography")
                SettingRow {label:Tr.t("Body font");ThemedComboBox {model:[Tr.t("System default")].concat(FontService.sans);currentIndex:Math.max(0,model.indexOf(root.design.bodyFont));onActivated:root.set("bodyFont",currentIndex?model[currentIndex]:"")}}
                SettingRow {label:Tr.t("Heading font");ThemedComboBox {model:[Tr.t("System default")].concat(FontService.sans);currentIndex:Math.max(0,model.indexOf(root.design.headingFont));onActivated:root.set("headingFont",currentIndex?model[currentIndex]:"")}}
                StyleSlider {key:"headerSize";label:Tr.t("Page title size");from:24;to:44;unit:" px"}
                StyleSlider {key:"controlFontSize";label:Tr.t("Control text size");from:11;to:19;unit:" px"}
                StyleSlider {key:"textScale";label:Tr.t("Text scale");from:85;to:145;unit:"%"}
            }
            SettingGroup {
                visible:root.tab==="details";title:Tr.t("Controls")
                StyleSlider {key:"rowHeight";label:Tr.t("Setting row height");from:46;to:92;unit:" px"}
                StyleSlider {key:"rowPadding";label:Tr.t("Setting row padding");from:4;to:24;unit:" px"}
                StyleSlider {key:"controlHeight";label:Tr.t("Button and field height");from:28;to:48;unit:" px"}
                StyleSlider {key:"controlRadius";label:Tr.t("Control rounding");from:0;to:20;unit:" px"}
                StyleSlider {key:"tabRadius";label:Tr.t("Tab rounding");from:0;to:24;unit:" px"}
                StyleSlider {key:"buttonRadius";label:Tr.t("Button rounding");from:0;to:24;unit:" px"}
                StyleSlider {key:"fieldRadius";label:Tr.t("Field rounding");from:0;to:20;unit:" px"}
                StyleSlider {key:"sliderTrackHeight";label:Tr.t("Slider thickness");from:2;to:10;unit:" px"}
                StyleSlider {key:"sliderThumbSize";label:Tr.t("Slider handle size");from:12;to:28;unit:" px"}
            }
            SettingGroup {
                visible:root.tab==="details";title:Tr.t("What to show")
                StyleToggle {key:"showProfile";label:Tr.t("Profile card")}
                StyleToggle {key:"showSearch";label:Tr.t("Sidebar search")}
                StyleToggle {key:"showCategoryLabels";label:Tr.t("Category headings")}
                StyleToggle {key:"sidebarIcons";label:Tr.t("Navigation icons")}
                StyleToggle {key:"showBreadcrumbs";label:Tr.t("Breadcrumbs")}
                StyleToggle {key:"showSavedStatus";label:Tr.t("Saved status")}
                StyleToggle {key:"headerIcon";label:Tr.t("Page title icon")}
                StyleToggle {key:"showPageDescription";label:Tr.t("Page descriptions")}
                StyleToggle {key:"showFooter";label:Tr.t("Previous and next navigation")}
                StyleToggle {key:"showLivePreview";label:Tr.t("Appearance preview")}
                StyleToggle {key:"showCardTitles";label:Tr.t("Card headings")}
                StyleToggle {key:"showHelp";label:Tr.t("Help hints")}
                StyleToggle {key:"rowDivider";label:Tr.t("Row dividers")}
                SettingField {label:Tr.t("Sidebar title");value:root.design.brandName||"Hyprland";onEdited:value=>root.set("brandName",value)}
            }
        }
        ColumnLayout {
            visible:root.tab==="colours" && root.design.showLivePreview!==false && root.width>=820
            Layout.preferredWidth:244;Layout.maximumWidth:244;Layout.alignment:Qt.AlignTop;spacing:18
            Rectangle {
                Layout.fillWidth:true;implicitHeight:342;radius:15;color:Theme.surfaceIn(QsWindow.window);border.width:1;border.color:Theme.borderIn(QsWindow.window)
                ColumnLayout {anchors.fill:parent;anchors.margins:16;spacing:16
                    RowLayout {Layout.fillWidth:true
                        Text {Layout.fillWidth:true;text:Tr.t("Settings preview");font.family:Theme.fontIn(QsWindow.window);font.pixelSize:11;color:Theme.mutedIn(QsWindow.window)}
                        Rectangle {width:5;height:5;radius:3;color:Theme.accentIn(QsWindow.window)}
                        Text {text:Tr.t("Live");font.pixelSize:10;color:Theme.mutedIn(QsWindow.window)}
                    }
                    SettingsMiniature {Layout.fillWidth:true;Layout.preferredHeight:170;colours:root.design;accent:Theme.accentIn(QsWindow.window)}
                    Text {Layout.fillWidth:true;text:Tr.t("A little glimpse of your look.\nChanges appear here as you go.");wrapMode:Text.WordWrap;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:12;color:Theme.mutedIn(QsWindow.window);lineHeight:1.3}
                    Item {Layout.fillHeight:true}
                }
            }
            Text {text:Tr.t("ON THIS PAGE");font.family:Theme.fontIn(QsWindow.window);font.pixelSize:10;font.letterSpacing:1.2;color:Theme.mutedIn(QsWindow.window)}
            Repeater {model:[Tr.t("Colour theme"),Tr.t("Accent colours"),Tr.t("Layout & typography")]
                Text {required property string modelData;text:modelData;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:12;color:Theme.mutedIn(QsWindow.window)}
            }
            Rectangle {Layout.fillWidth:true;implicitHeight:100;radius:12;color:Qt.alpha(Theme.accentIn(QsWindow.window),.16)
                Text {anchors.fill:parent;anchors.margins:16;text:Tr.t("Less searching. More doing.\n\nPress Ctrl K to jump to any setting.");wrapMode:Text.WordWrap;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:12;color:Theme.textIn(QsWindow.window)}
            }
        }
    }
}
