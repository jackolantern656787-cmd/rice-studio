//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick
import "pill" as Pill
import "pill/Singletons" as Local

ShellRoot {
    id: root

    IpcHandler {
        target: "desktop"
        function setScreen(name: string): void { Local.Session.monitorName = name }
        function status(): string { return JSON.stringify({screens: Quickshell.screens.length, mode: Local.Theme.mode}) }
    }
    property bool controlCenterLoaded: false
    property bool powerMenuLoaded: false
    property bool settingsLoaded: false
    property int aiUsageAnchorX: 0
    property string settingsPage: "bar"

    property var trayBar: null
    Variants {
        model: Quickshell.screens
        delegate: Pill.Bar {
            onTrayMenuRequested: (item, anchorX) => { root.trayBar = this; trayMenu.openMenu(item, anchorX) }
        }
    }
    Pill.Pill {}
    Pill.AiUsagePanel { id: aiUsagePanel; anchorX: root.aiUsageAnchorX }
    Pill.TrayMenu {
        id: trayMenu
        // @note right click while open: switch to the tray item under the cursor, or close
        onSwitchRequested: globalX => {
            const target = root.trayBar?.trayItemAt(globalX)
            if (target && target.modelData !== trayMenu.trayItem) {
                const pos = target.mapToItem(null, target.width / 2, 0)
                trayMenu.openMenu(target.modelData, Math.round(pos.x))
            } else {
                trayMenu.close()
            }
        }
    }
    // Keystroke capture is outside this preset and remains unloaded.

    Loader {
        id: controlCenterLoader
        active: root.controlCenterLoaded
        sourceComponent: Component {
            Pill.ControlCenter { onDismissed: root.controlCenterLoaded = false }
        }
    }

    IpcHandler {
        target: "aiUsage"
        function toggle(anchorX: int): void {
            root.aiUsageAnchorX = anchorX
            aiUsagePanel.anchorX = anchorX
            aiUsagePanel.toggle()
        }
        function refresh(): void { aiUsagePanel.refresh(true) }
    }

    Loader {
        id: settingsLoader
        active: root.settingsLoaded
        sourceComponent: Component {
            Pill.SettingsWindow {
                page: root.settingsPage
                onDismissed: {
                    root.settingsPage = "bar"
                    root.settingsLoaded = false
                }
            }
        }
    }

    Loader {
        id: powerMenuLoader
        active: root.powerMenuLoaded
        sourceComponent: Component {
            Pill.PowerMenu { onDismissed: root.powerMenuLoaded = false }
        }
    }

    IpcHandler {
        target: "powerMenu"
        function toggle(): void {
            if (powerMenuLoader.item)
                powerMenuLoader.item.toggle()
            else {
                root.powerMenuLoaded = true
                powerMenuOpenTimer.restart()
            }
        }
    }

    Timer {
        id: powerMenuOpenTimer
        interval: 0
        onTriggered: powerMenuLoader.item?.toggle()
    }

    IpcHandler {
        target: "controlCenter"
        function toggle(): void {
            if (controlCenterLoader.item)
                controlCenterLoader.item.toggle()
            else {
                root.controlCenterLoaded = true
                controlCenterOpenTimer.restart()
            }
        }
    }

    IpcHandler {
        target: "pillSettings"
        function toggle(): void {
            if (settingsLoader.item)
                settingsLoader.item.close()
            else {
                root.settingsPage = "bar"
                root.settingsLoaded = true
            }
        }
        function open(page: string): void {
            root.settingsPage = page
            if (settingsLoader.item) {
                settingsLoader.item.page = page
                settingsLoader.item.open = true
            } else {
                root.settingsLoaded = true
            }
        }
    }

    Timer {
        id: controlCenterOpenTimer
        interval: 0
        onTriggered: controlCenterLoader.item?.toggle()
    }
}
