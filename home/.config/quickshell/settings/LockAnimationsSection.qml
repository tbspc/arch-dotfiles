import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"
import "../components"
SettingsSection {
    SettingGroup{title:Tr.t("Desktop bar entry");note:Tr.t("Open the lock symbol first, then reveal the active bar configuration.")
        SettingRow{label:Tr.t("Animate on login");ToggleSwitch{checked:SettingsService.barEntryEnabled;onToggled:checked=>SettingsService.set("barEntryEnabled",checked)}}
        SettingRow{label:Tr.t("Also animate on unlock");ToggleSwitch{checked:SettingsService.barEntryOnUnlock;onToggled:checked=>SettingsService.set("barEntryOnUnlock",checked)}}
        SettingRow{label:Tr.t("Reveal style");SegmentedControl{options:[{id:"fade",label:Tr.t("Fade")},{id:"smooth",label:Tr.t("Smooth")},{id:"bounce",label:Tr.t("Bounce")},{id:"none",label:Tr.t("Instant")}];current:SettingsService.barEntryAnimation;onSelected:id=>SettingsService.set("barEntryAnimation",id)}}
        SettingSlider{label:Tr.t("Lock symbol pause");from:0;to:600;unit:" ms";value:SettingsService.barEntryHold;onMoved:value=>SettingsService.set("barEntryHold",Math.round(value))}
        SettingSlider{label:Tr.t("Unlock lead-in");from:0;to:500;unit:" ms";value:SettingsService.barEntryUnlockLead;onMoved:value=>SettingsService.set("barEntryUnlockLead",Math.round(value))}
        SettingSlider{label:Tr.t("Reveal duration");from:100;to:1200;unit:" ms";value:SettingsService.barEntryDuration;onMoved:value=>SettingsService.set("barEntryDuration",Math.round(value))}
        SettingRow{label:Tr.t("Try without locking");PillButton{text:Tr.t("Preview bar entry");onClicked:LockMotionService.preview()}}
    }
    function applyMotion(style: string, speed: int, bounce: int): void {
        SettingsService.set("lockAnimationMovement", style)
        SettingsService.set("lockAnimationSpeed", speed)
        SettingsService.set("lockAnimationBounciness", bounce)
    }
    SettingGroup {
        title: Tr.t("Lock screen animations")
        note: Tr.t("Optional lock Island at the bar's normal position. Your session still locks immediately.")
        SettingRow {
            label: Tr.t("Show bar while locked")
            reading:Tr.t("Off hides the extra lock bar while preserving the full-screen fade or slide")
            ToggleSwitch {
                checked: SettingsService.lockIslandEnabled
                onToggled: checked => {
                    SettingsService.set("lockIslandEnabled",checked)
                }
            }
        }
        SettingRow {
            label: Tr.t("Animation")
            SegmentedControl {
                options: [{id:"fade",label:Tr.t("Fade")},{id:"soft-slide",label:Tr.t("Soft slide")},{id:"bar-slide",label:Tr.t("Bar slide")},{id:"none",label:Tr.t("None")}]
                current: SettingsService.lockAnimation
                onSelected: id => SettingsService.set("lockAnimation",id)
            }
        }
        SettingRow {
            visible:["fade","soft-slide"].includes(SettingsService.lockAnimation)
            label:Tr.t("Fade easing")
            SegmentedControl{options:[{id:"smooth",label:Tr.t("Soft")},{id:"glide",label:Tr.t("Quick")},{id:"quint",label:Tr.t("Video reference")},{id:"linear",label:Tr.t("Linear")}];current:SettingsService.lockAnimationMovement;onSelected:id=>SettingsService.set("lockAnimationMovement",id)}
        }
        SettingRow {
            visible:["fade","soft-slide"].includes(SettingsService.lockAnimation)
            label:Tr.t("Unlock easing")
            ThemedComboBox{model:[{id:"follow",name:Tr.t("Match locking")},{id:"smooth",name:Tr.t("Soft")},{id:"glide",name:Tr.t("Quick")},{id:"quint",name:Tr.t("Video ease-out")},{id:"linear",name:Tr.t("Linear")}];textRole:"name";currentIndex:Math.max(0,model.findIndex(p=>p.id===SettingsService.lockUnlockMovement));onActivated:index=>SettingsService.set("lockUnlockMovement",model[index].id)}
        }
        SettingSlider{label:Tr.t("Unlock duration");reading:SettingsService.lockUnlockDuration===0?Tr.t("Match locking"):SettingsService.lockUnlockDuration+" ms";from:0;to:1200;unit:" ms";value:SettingsService.lockUnlockDuration;onMoved:value=>SettingsService.set("lockUnlockDuration",Math.round(value))}
        SettingRow{label:Tr.t("Bar ↔ lock symbol");reading:Tr.t("For fade and soft-slide lock transitions");SegmentedControl{options:[{id:"fade",label:Tr.t("Fade")},{id:"smooth",label:Tr.t("Smooth")},{id:"bounce",label:Tr.t("Bounce")},{id:"none",label:Tr.t("Instant")}];current:SettingsService.lockIslandTransition;onSelected:id=>SettingsService.set("lockIslandTransition",id)}}
        SettingSlider{label:Tr.t("Bar transition duration");from:100;to:650;unit:" ms";value:SettingsService.lockIslandTransitionDuration;onMoved:value=>SettingsService.set("lockIslandTransitionDuration",Math.round(value))}
        SettingSlider{label:Tr.t("Open padlock pause");from:0;to:600;unit:" ms";value:SettingsService.lockIslandOpenHold;onMoved:value=>SettingsService.set("lockIslandOpenHold",Math.round(value))}
        SettingSlider{label:Tr.t("Padlock closing duration");from:100;to:700;unit:" ms";value:SettingsService.lockIslandCloseDuration;onMoved:value=>SettingsService.set("lockIslandCloseDuration",Math.round(value))}
        SettingSlider {
            label: Tr.t("Base duration")
            value: SettingsService.lockAnimationDuration
            from: 200; to: 1200; unit: " ms"
            onMoved: value => SettingsService.set("lockAnimationDuration",Math.round(value))
        }
        SettingSlider {
            visible: SettingsService.lockAnimation !== "none"
            label: Tr.t("Speed")
            value: SettingsService.lockAnimationSpeed
            from: 50; to: 200; unit: "%"
            onMoved: value => SettingsService.set("lockAnimationSpeed", Math.round(value))
        }
        SettingRow {
            visible: SettingsService.lockAnimation !== "none"
            label: Tr.t("Effective duration")
            reading: `${Math.round(SettingsService.lockDuration * Theme.motion)} ms`
        }
        SettingRow {
            visible: SettingsService.lockAnimation === "bar-slide"
            label: Tr.t("Movement presets")
            RowLayout {
                spacing: 6
                PillButton { text: Tr.t("Gentle"); onClicked: applyMotion("smooth", 80, 25) }
                PillButton { text: Tr.t("Snappy"); onClicked: applyMotion("glide", 150, 25) }
                PillButton { text: Tr.t("Springy"); onClicked: applyMotion("spring", 90, 45) }
            }
        }
        SettingRow {
            visible: SettingsService.lockAnimation === "bar-slide"
            label: Tr.t("Movement")
            SegmentedControl {
                options: [{id:"smooth",label:Tr.t("Smooth")},{id:"glide",label:Tr.t("Glide")},{id:"linear",label:Tr.t("Linear")}]
                current: SettingsService.lockAnimationMovement
                onSelected: id => SettingsService.set("lockAnimationMovement", id)
            }
        }
        SettingRow {
            visible: SettingsService.lockAnimation === "bar-slide"
            label: Tr.t("Bouncy movement")
            SegmentedControl {
                options: [{id:"spring",label:Tr.t("Spring")},{id:"bounce",label:Tr.t("Bounce")}]
                current: SettingsService.lockAnimationMovement
                onSelected: id => SettingsService.set("lockAnimationMovement", id)
            }
        }
        SettingSlider {
            visible: SettingsService.lockAnimation === "bar-slide"
                && ["spring","bounce"].includes(SettingsService.lockAnimationMovement)
            label: Tr.t("Bounciness")
            value: SettingsService.lockAnimationBounciness
            from: 0; to: 100; unit: "%"
            onMoved: value => SettingsService.set("lockAnimationBounciness", Math.round(value))
        }
        SettingSlider {
            visible: SettingsService.lockAnimation === "bar-slide"
                && ["spring","bounce"].includes(SettingsService.lockAnimationMovement)
            label: Tr.t("Rebounds")
            value: SettingsService.lockAnimationRebounds
            from: 1; to: 3; stepSize: 1
            onMoved: value => SettingsService.set("lockAnimationRebounds", Math.round(value))
        }
        SettingRow {
            visible: SettingsService.lockAnimation === "bar-slide"
            label: Tr.t("Full-screen slide")
            reading: Tr.t("The Island carries the lock screen or desktop down, then exits below the screen")
        }
    }
}
