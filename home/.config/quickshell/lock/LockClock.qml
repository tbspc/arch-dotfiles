import QtQuick
import Quickshell
import "../services"
import "common"

SharedClockFace {
    id: root
    property var at: null
    configuration: LockStyleService.values
    now: root.at !== null ? root.at : clock.date
    SystemClock { id: clock; precision: SystemClock.Minutes; enabled: root.at === null }
}
