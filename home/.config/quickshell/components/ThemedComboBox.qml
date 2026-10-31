import QtQuick
import Quickshell
import QtQuick.Controls as Controls
import "../theme"
import "../services"

Controls.ComboBox {
    id:root
    readonly property var styleWindow:QsWindow.window
    readonly property color popupBase:Theme.settingsWindow(root.styleWindow)?SettingsDesignService.designStyle.cardBackground||Theme.islandGround:Theme.islandGround
    implicitHeight:34
    implicitWidth:240
    font.family:Theme.fontIn(root.styleWindow)
    font.pixelSize:Theme.fontSizeRegular
    leftPadding:12
    rightPadding:32
    contentItem:Text{
        text:root.displayText
        font:root.font
        color:Theme.textIn(root.styleWindow)
        verticalAlignment:Text.AlignVCenter
        elide:Text.ElideRight
    }
    background:Rectangle{
        radius:Theme.radiusIn(root.styleWindow,"controlRadius",Theme.radiusSmall)
        color:root.hovered?Theme.colourIn(root.styleWindow,"hoverColor",Theme.islandSurfaceHover):Theme.colourIn(root.styleWindow,"fieldBackground",Theme.islandSurface)
        border.width:1
        border.color:root.popup.visible||root.activeFocus?Theme.accentIn(root.styleWindow):Theme.colourIn(root.styleWindow,"borderColor",Theme.border)
        Behavior on border.color{ColorAnimation{duration:100}}
    }
    indicator:Text{
        x:root.width-width-11;y:(root.height-height)/2
        text:root.popup.visible?"󰅃":"󰅀"
        color:root.popup.visible?Theme.accentIn(root.styleWindow):Theme.mutedIn(root.styleWindow)
        font.family:Theme.fontMono;font.pixelSize:13
    }
    delegate:Controls.ItemDelegate{
        required property int index
        required property var modelData
        width:root.popup.width-12
        height:34
        highlighted:root.highlightedIndex===index
        contentItem:Text{
            text:root.textRole?modelData[root.textRole]:modelData
            font:root.font
            color:index===root.currentIndex?Theme.accentIn(root.styleWindow):Theme.textIn(root.styleWindow)
            verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight
        }
        background:Rectangle{
            radius:Theme.radiusIn(root.styleWindow,"controlRadius",Theme.radiusSmall)
            color:parent.highlighted?Qt.alpha(Theme.accentIn(root.styleWindow),0.16):parent.hovered?Theme.colourIn(root.styleWindow,"hoverColor",Theme.islandSurfaceHover):"transparent"
        }
    }
    popup:Controls.Popup{
        y:root.height+6
        z:10000
        margins:8
        closePolicy:Controls.Popup.CloseOnEscape|Controls.Popup.CloseOnPressOutside
        width:root.width
        height:Math.min(420,menuList.contentHeight+12)
        padding:6
        contentItem:ListView{
            id:menuList
            clip:true
            model:root.popup.visible?root.delegateModel:null
            currentIndex:root.highlightedIndex
            boundsBehavior:Flickable.StopAtBounds
            reuseItems:true
            Controls.ScrollIndicator.vertical:Controls.ScrollIndicator{}
        }
        background:Rectangle{color:Qt.rgba(root.popupBase.r,root.popupBase.g,root.popupBase.b,1);radius:Theme.radiusMedium;border.width:1;border.color:Theme.colourIn(root.styleWindow,"borderColor",Theme.border)}
        enter:Transition{NumberAnimation{property:"opacity";from:0;to:1;duration:100;easing.type:Easing.OutCubic}}
        exit:Transition{NumberAnimation{property:"opacity";from:1;to:0;duration:70}}
        onOpened:menuList.positionViewAtIndex(root.currentIndex,ListView.Contain)
    }
}
