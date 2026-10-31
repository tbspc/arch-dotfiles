import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../services"
import "../theme"
            RowLayout { objectName:"design:LauncherPanel:16";
    id:root
    property var entry:({})
    property bool selected:false
    property bool preview:false
    property color tint:Theme.accentIn(QsWindow.window)
    property var appearance:LauncherPresetService.style
                anchors.fill: parent
                anchors.leftMargin: root.appearance.rowPadding
                anchors.rightMargin: root.appearance.rowPadding
                spacing: root.appearance.contentGap

                // App icons sit in softly rounded tiles, like the reference.
                // Other result kinds retain their glyphs and thumbnails.
                Item { objectName:"design:LauncherPanel:17";
                    id: badge

                    // Named rather than reached through `parent`, which inside
                    // this binding is the row.
                    readonly property bool isApp: root.entry.kind === "app"
                    readonly property string iconSource: badge.isApp && root.entry.icon
                        ? Theme.appIcon(root.entry.icon) : ""

                    // Copied images show a thumbnail: two screenshots often
                    // share a name and a size.
                    readonly property string picture: root.entry.picture ?? ""

                    // An emoji is its own mark, drawn in colour.
                    readonly property string glyph: root.entry.glyph ?? ""

                    visible:root.appearance.showIcons
                    Layout.preferredWidth: root.appearance.iconSize
                    Layout.preferredHeight: root.appearance.iconSize
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle { objectName:"design:LauncherPanel:18";
                        anchors.fill: parent
                        visible: badge.isApp && root.appearance.iconTiles
                        radius: root.appearance.iconRadius
                        color: root.selected ? Qt.rgba(1, 1, 1, 0.07)
                            : Qt.rgba(1, 1, 1, 0.035)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.045)

                        Behavior on color {
                            ColorAnimation { duration: Theme.durationFast }
                        }
                    }

                    Image { objectName:"design:LauncherPanel:19";
                        id: appIcon
                        anchors.fill: parent
                        anchors.margins: badge.isApp ? root.appearance.iconPadding : 0
                        fillMode: Image.PreserveAspectFit
                        source: badge.iconSource
                        visible: badge.iconSource !== "" && status === Image.Ready
                        sourceSize.width:root.appearance.iconSize*2
                        sourceSize.height:root.appearance.iconSize*2
                        asynchronous: !root.preview
                    }

                    // ClippingRectangle rather than `clip`, which is
                    // rectangular and would square off the corners.
                    ClippingRectangle { objectName:"design:LauncherPanel:20";
                        anchors.fill: parent
                        visible: badge.picture !== "" && thumbnail.status === Image.Ready
                        radius: width * Theme.pictureCorner
                        color: Theme.surfaceHoverIn(QsWindow.window)

                        Image { objectName:"design:LauncherPanel:21";
                            id: thumbnail

                            anchors.fill: parent
                            source: badge.picture
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: !root.preview
                            sourceSize.width:root.appearance.iconSize*2
                            sourceSize.height:root.appearance.iconSize*2
                        }
                    }

                    Text { objectName:"design:LauncherPanel:22";
                        anchors.centerIn: parent
                        visible: badge.glyph !== ""
                        text: badge.glyph
                        font.family: root.appearance.fontFamily?Theme.fontOf(root.appearance.fontFamily):Theme.fontFamily
                        font.pixelSize:root.appearance.iconSize*0.7
                    }

                    Rectangle { objectName:"design:LauncherPanel:23";
                        anchors.fill: parent
                        visible: !appIcon.visible && badge.picture === "" && badge.glyph === ""
                        radius: badge.isApp ? root.appearance.iconRadius : width / 2
                        color: Theme.surfaceHoverIn(QsWindow.window)

                        Text { objectName:"design:LauncherPanel:24";
                            anchors.centerIn: parent
                            text: badge.isApp ? "󰀻" : root.entry.icon
                            font.family: Theme.fontMono
                            font.pixelSize: 14
                            color: root.tint
                        }
                    }
                }

                ColumnLayout { objectName:"design:LauncherPanel:25";
                    Layout.fillWidth: true
                    spacing:root.appearance.textGap

                    Text { objectName:"design:LauncherPanel:26";
                        Layout.fillWidth: true
                        text: root.entry.name
                        elide: Text.ElideRight
                        font.family: root.entry.kind === "calculation"
                            ? Theme.fontMono : (root.appearance.fontFamily?Theme.fontOf(root.appearance.fontFamily):Theme.fontFamily)
                        font.pixelSize: root.entry.kind === "app"
                            ? root.appearance.titleSize : root.appearance.titleSize
                        font.weight: root.entry.kind === "calculation"
                            ? Font.DemiBold : root.entry.kind === "app" ? root.appearance.titleWeight : root.appearance.titleWeight
                        color:root.appearance.foregroundColor||Theme.text
                    }

                    Text { objectName:"design:LauncherPanel:27";
                        Layout.fillWidth: true
                        text: root.entry.subtitle
                        visible: root.appearance.showSubtitles && root.entry.subtitle !== ""
                        elide: Text.ElideRight
                        font.family: root.appearance.fontFamily?Theme.fontOf(root.appearance.fontFamily):Theme.fontFamily
                        font.pixelSize: root.entry.kind === "app"
                            ? root.appearance.subtitleSize : root.appearance.subtitleSize
                        color:root.appearance.mutedColor||Theme.textMuted
                    }
                }

                // Marks apps kept on the dock, which is why they rank near the
                // top of an empty query.
                Text { objectName:"design:LauncherPanel:28";
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.appearance.showPinned && root.entry.kind === "app"
                        && LauncherService.favourites.indexOf(root.entry.id) >= 0
                    text: "󱂩"
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    color:root.appearance.mutedColor||Theme.textMuted
                }

                // A mode row shows its sigil as a keycap, so it also teaches
                // the shortcut. The box gives every character the same size
                // and centre; bare, `'` is a thin stroke at the top of its
                // line.
                Rectangle { objectName:"design:LauncherPanel:29";
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 20
                    visible: (root.entry.sigil ?? "") !== ""
                    radius: Theme.radiusSmall - 2
                    color: Theme.island
                    border.color: Theme.borderIn(QsWindow.window)
                    border.width: 1

                    Text { objectName:"design:LauncherPanel:30";
                        anchors.centerIn: parent
                        text: root.entry.sigil ?? ""
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.accentIn(QsWindow.window)
                    }
                }
            }
