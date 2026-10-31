import QtQuick
import "../components"
import "../services"
import "../theme"
Column {
 id:root
 width:parent?parent.width:implicitWidth
 spacing:16
 visible:SettingsService.islandHoverDesign!=="classic"
 readonly property var values:Object.assign({},SettingsService.pristine.islandHoverLayout,SettingsService.islandHoverLayout)
 SettingGroup {
  title:Tr.t("Hover view customization")
  note:Tr.t("Independent sizes and positions for the expanded view. Save your layout with the Calendar and media module presets.")
  SettingRow {label:Tr.t("Use custom hover layout");ToggleSwitch {checked:root.values.enabled;onToggled:value=>SettingsService.set("islandHoverLayout",Object.assign({},root.values,{enabled:value}))}}
  SettingRow {label:Tr.t("Follow bar icon and workspace styling");ToggleSwitch {checked:root.values.followBarStyle!==false;onToggled:value=>SettingsService.setHoverLayout("followBarStyle",value)}}
  SettingRow {label:Tr.t("Reset hover layout");PillButton {text:Tr.t("Reset");onClicked:SettingsService.set("islandHoverLayout",Object.assign({},SettingsService.pristine.islandHoverLayout,{enabled:false}))}}
 }
 SettingGroup {visible:root.values.enabled;title:Tr.t("Dimensions")
  SettingSlider {label:Tr.t("Hover view width");from:240;to:1200;unit:" px";value:root.values.width;onMoved:value=>SettingsService.setHoverLayout("width",Math.round(value))}
  SettingSlider {label:Tr.t("Hover view height");from:40;to:240;unit:" px";value:root.values.height;onMoved:value=>SettingsService.setHoverLayout("height",Math.round(value))}
 }
 SettingGroup {visible:root.values.enabled;title:Tr.t("Clock and date")
  SettingSlider {label:Tr.t("Clock size · bar and hover");from:10;to:64;unit:" px";value:SettingsService.islandClockSize;onMoved:value=>SettingsService.setSharedClockSize(value)}
  SettingSlider {label:Tr.t("Date size");from:8;to:32;unit:" px";value:root.values.dateSize;onMoved:value=>SettingsService.setHoverLayout("dateSize",Math.round(value))}
  SettingSlider {label:Tr.t("Clock\u2013date spacing");from:0;to:48;unit:" px";value:root.values.dateGap;onMoved:value=>SettingsService.setHoverLayout("dateGap",Math.round(value))}
  SettingSlider {label:Tr.t("Clock horizontal offset");from:-160;to:160;unit:" px";value:root.values.clockX;onMoved:value=>SettingsService.setHoverLayout("clockX",Math.round(value))}
  SettingSlider {label:Tr.t("Clock vertical offset");from:-80;to:80;unit:" px";value:root.values.clockY;onMoved:value=>SettingsService.setHoverLayout("clockY",Math.round(value))}
 }
 SettingGroup {visible:root.values.enabled;title:Tr.t("Left and right groups")
  SettingSlider {label:Tr.t("Left group inset");from:0;to:180;unit:" px";value:root.values.leftPadding;onMoved:value=>SettingsService.setHoverLayout("leftPadding",Math.round(value))}
  SettingSlider {label:Tr.t("Right group inset");from:0;to:180;unit:" px";value:root.values.rightPadding;onMoved:value=>SettingsService.setHoverLayout("rightPadding",Math.round(value))}
  SettingSlider {label:Tr.t("Left group vertical offset");from:-60;to:60;unit:" px";value:root.values.leftY;onMoved:value=>SettingsService.setHoverLayout("leftY",Math.round(value))}
  SettingSlider {label:Tr.t("Right group vertical offset");from:-60;to:60;unit:" px";value:root.values.rightY;onMoved:value=>SettingsService.setHoverLayout("rightY",Math.round(value))}
  SettingSlider {label:Tr.t("Workspace size");from:30;to:200;unit:"%";value:root.values.workspaceScale;onMoved:value=>SettingsService.setHoverLayout("workspaceScale",Math.round(value))}
  SettingSlider {label:Tr.t("Signal size");from:30;to:200;unit:"%";value:root.values.signalScale;onMoved:value=>SettingsService.setHoverLayout("signalScale",Math.round(value))}
  SettingSlider {label:Tr.t("Battery size");from:30;to:200;unit:"%";value:root.values.batteryScale;onMoved:value=>SettingsService.setHoverLayout("batteryScale",Math.round(value))}
 }
 SettingGroup {visible:root.values.enabled;title:Tr.t("Headers")
  SettingSlider {label:Tr.t("Header vertical position");from:0;to:100;unit:" px";value:root.values.headerY;onMoved:value=>SettingsService.setHoverLayout("headerY",Math.round(value))}
  SettingSlider {label:Tr.t("Header height");from:12;to:48;unit:" px";value:root.values.headerHeight;onMoved:value=>SettingsService.setHoverLayout("headerHeight",Math.round(value))}
  SettingSlider {label:Tr.t("Header text size");from:8;to:28;unit:" px";value:root.values.headerSize;onMoved:value=>SettingsService.setHoverLayout("headerSize",Math.round(value))}
  SettingSlider {label:Tr.t("Header icon size");from:8;to:28;unit:" px";value:root.values.headerIconSize;onMoved:value=>SettingsService.setHoverLayout("headerIconSize",Math.round(value))}
  SettingSlider {label:Tr.t("Left header inset");from:0;to:180;unit:" px";value:root.values.headerLeftX;onMoved:value=>SettingsService.setHoverLayout("headerLeftX",Math.round(value))}
  SettingSlider {label:Tr.t("Right header inset");from:0;to:180;unit:" px";value:root.values.headerRightX;onMoved:value=>SettingsService.setHoverLayout("headerRightX",Math.round(value))}
 }
 SettingGroup {visible:root.values.enabled&&root.values.followBarStyle===false;title:Tr.t("Workspace marks")
  SettingSlider {label:Tr.t("Active mark width");from:2;to:28;unit:" px";value:root.values.workspaceWidth;onMoved:value=>SettingsService.setHoverLayout("workspaceWidth",Math.round(value))}
  SettingSlider {label:Tr.t("Active mark height");from:2;to:40;unit:" px";value:root.values.workspaceHeight;onMoved:value=>SettingsService.setHoverLayout("workspaceHeight",Math.round(value))}
  SettingSlider {label:Tr.t("Inactive mark width");from:2;to:28;unit:" px";value:root.values.workspaceInactiveWidth;onMoved:value=>SettingsService.setHoverLayout("workspaceInactiveWidth",Math.round(value))}
  SettingSlider {label:Tr.t("Inactive mark height");from:2;to:40;unit:" px";value:root.values.workspaceInactiveHeight;onMoved:value=>SettingsService.setHoverLayout("workspaceInactiveHeight",Math.round(value))}
  SettingSlider {label:Tr.t("Space between marks");from:0;to:20;unit:" px";value:root.values.workspaceGap;onMoved:value=>SettingsService.setHoverLayout("workspaceGap",Math.round(value))}
 }
 SettingGroup {
  visible:root.values.enabled
  title:Tr.t("Mini media player")
  SettingRow {label:Tr.t("Show mini player");ToggleSwitch {checked:root.values.mediaEnabled;onToggled:value=>SettingsService.setHoverLayout("mediaEnabled",value)}}
  SettingRow {visible:root.values.mediaEnabled;label:Tr.t("Show playback buttons");ToggleSwitch {checked:root.values.mediaControls;onToggled:value=>SettingsService.setHoverLayout("mediaControls",value)}}
  SettingSlider {visible:root.values.mediaEnabled;label:Tr.t("Player width");from:160;to:600;unit:" px";value:root.values.mediaWidth;onMoved:value=>SettingsService.setHoverLayout("mediaWidth",Math.round(value))}
  SettingSlider {visible:root.values.mediaEnabled;label:Tr.t("Player height");from:40;to:120;unit:" px";value:root.values.mediaHeight;onMoved:value=>SettingsService.setHoverLayout("mediaHeight",Math.round(value))}
  SettingSlider {visible:root.values.mediaEnabled;label:Tr.t("Player horizontal offset");from:-240;to:240;unit:" px";value:root.values.mediaX;onMoved:value=>SettingsService.setHoverLayout("mediaX",Math.round(value))}
  SettingSlider {visible:root.values.mediaEnabled;label:Tr.t("Player vertical position");from:0;to:200;unit:" px";value:root.values.mediaY;onMoved:value=>SettingsService.setHoverLayout("mediaY",Math.round(value))}
  SettingSlider {visible:root.values.mediaEnabled;label:Tr.t("Song title size");from:8;to:28;unit:" px";value:root.values.mediaTitleSize;onMoved:value=>SettingsService.setHoverLayout("mediaTitleSize",Math.round(value))}
  SettingSlider {visible:root.values.mediaEnabled;label:Tr.t("Artist text size");from:8;to:24;unit:" px";value:root.values.mediaArtistSize;onMoved:value=>SettingsService.setHoverLayout("mediaArtistSize",Math.round(value))}
  SettingSlider {visible:root.values.mediaEnabled;label:Tr.t("Artwork size");from:16;to:96;unit:" px";value:root.values.mediaArtSize;onMoved:value=>SettingsService.setHoverLayout("mediaArtSize",Math.round(value))}
 }

}
