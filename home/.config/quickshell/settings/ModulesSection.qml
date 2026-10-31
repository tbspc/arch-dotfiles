// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   M O D U L E S   S E C T I O N                                          │
// │   modules · what they know, wherever they are shown                      │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../theme"
import "../services"
import "../components"
import "../desktop"

// The modules' own settings: read by a chip on the bar, a widget on the
// desktop and a panel alike, so they belong to none of those pages.
SettingsSection {
    id: root
    Loader {Layout.fillWidth:true;active:root.tab==="colours";visible:active;sourceComponent:ModuleColoursSection {}}

    Loader {
        Layout.fillWidth: true
        active: root.tab === "rounding"
        visible: active
        sourceComponent: ModuleRoundingSection {}
    }

    // Unused: this page has no parts, but `SettingsPanel` sets it on all pages.
    property string tab: ""
    function openFullscreenEditor(): void { ModuleService.editorRequested() }
    SettingRow {
        label:Tr.t("Edit all modules with a full-screen preview")
        PillButton { text:Tr.t("Full-screen module editor"); onClicked:root.openFullscreenEditor() }
    }


    SettingGroup {
        visible: root.tab === "weather"
        title: Tr.t("Weather")
        note: Tr.t("A city, a postcode or an airport code.")
        hint: Tr.t("Left empty, wttr.in guesses from your connection's IP address, which can be far off. A city, postcode or airport code is more reliable, and the bar uses the same place.")

        // wttr.in answers an unknown place with prose and the widget
        // keeps its last reading, so the error is shown here.
        SettingField {
            label: Tr.t("Location")
            reading: WeatherService.placeUnknown
                ? Tr.t("No such place — the last reading is still showing") : ""
            alarm: WeatherService.placeUnknown
            placeholder: Tr.t("Wherever the request comes from")
            value: SettingsService.weatherPlace
            onEdited: value => SettingsService.set("weatherPlace", value.trim())
        }
    }

    SettingGroup {
        visible: root.tab === "github"
        title: "GitHub"
        note: Tr.t("Whose public contribution graph to draw.")
        hint: Tr.t("The graph is read from the public profile page, so no token or account is needed. It stays empty until you enter a username.")

        // An unknown user returns a page with no calendar and the widget
        // keeps its last grid, so the error is shown here.
        SettingField {
            label: Tr.t("Username")
            reading: GithubService.userUnknown
                ? Tr.t("No such profile — the last grid is still showing") : ""
            alarm: GithubService.userUnknown
            placeholder: Tr.t("Nobody yet")
            value: SettingsService.githubUser
            onEdited: value => SettingsService.set(
                "githubUser", value.trim().replace(/^@/, ""))
        }
    }

    SettingGroup {
        visible: root.tab === "markets"
        title: Tr.t("Markets")
        note: Tr.t("The coins and currencies to follow, separated by commas.")
        hint: Tr.t("A coin alone is priced in US dollars and BTC/EUR in euros; two currencies, such as EUR/USD, follow the European Central Bank's daily rate. Prices come from CoinGecko and Frankfurter, which see what you follow but need no account. The bar shows the first one.")

        // A symbol neither source knows is dropped from the widget, so
        // it is named here.
        SettingField {
            label: Tr.t("Follow")
            reading: MarketsService.unknown.length > 0
                ? `${Tr.t("Not found:")} ${MarketsService.unknown.join(", ")}` : ""
            alarm: MarketsService.unknown.length > 0
            placeholder: "BTC, ETH, EUR/USD"
            value: SettingsService.markets
            onEdited: value => SettingsService.set("markets", value.trim())
        }
    }

    // The tiles draw the pet itself, one in each style, and blink while
    // the pointer is on them.

    SettingGroup {
        visible: root.tab === "lyrics"
        title: Tr.t("Lyrics")
        note: Tr.t("The words of whatever is playing, wherever they are shown.")
        hint: Tr.t("Looked up on lrclib.net by title and artist, which needs no account. They show in the island's glance and its media card, in the desktop's lyrics widget and on the lock screen when it is set to show them.")

        SettingRow {
            label: Tr.t("Look them up")
            reading: SettingsService.lyrics
                ? Tr.t("The playing track's lyrics are looked up on lrclib.net")
                : Tr.t("No lyrics, and nothing is looked up")

            ToggleSwitch {
                checked: SettingsService.lyrics
                onToggled: checked => SettingsService.set("lyrics", checked)
            }
        }
    }

    SettingGroup {
        visible: root.tab === "notes"
        title: Tr.t("Notes")
        note: Tr.t("A note on the wallpaper is written the same way as one in the panel.")

        SettingRow {
            label: Tr.t("Body font")
            SegmentedControl {
                options: [{id:"",label:Tr.t("Default")},{id:"Inter",label:Tr.t("Sans")},{id:"JetBrainsMono Nerd Font",label:Tr.t("Mono")},{id:"Georgia",label:Tr.t("Serif")},{id:"@clock",label:Theme.fontFamily}]
                current: SettingsService.notesBodyFont
                onSelected: id => SettingsService.set("notesBodyFont",id)
            }
        }
        SettingField {
            label: Tr.t("Custom body font")
            placeholder: Tr.t("Installed font family, or blank for default")
            value: SettingsService.notesBodyFont==="@clock"?Theme.fontFamily:SettingsService.notesBodyFont
            onEdited: value => SettingsService.set("notesBodyFont", value.trim())
        }
        SettingRow {
            label: Tr.t("Handwriting")
            reading: SettingsService.notesHandwriting
                ? Tr.t("The signature's script") : Tr.t("The interface face")

            ToggleSwitch {
                checked: SettingsService.notesHandwriting
                onToggled: checked => SettingsService.set("notesHandwriting", checked)
            }
        }
    }
}
