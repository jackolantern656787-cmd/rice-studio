import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root
    FontLoader { source: "RicePixel.ttf" }
    property string selected: ""
    property string popup: ""
    onSelectedChanged: popup = ""
    IpcHandler {
        target: "pixel"
        function toggle(panel: string): void {
            if (root.selected !== "pixel" || ["system","ram","calendar","audio","network","notifications"].indexOf(panel)<0) return;
            root.popup = root.popup === panel ? "" : panel;
        }
        function close(): void { root.popup = ""; }
    }
    FileView {
        id: selection
        path: "@STUDIO_STATE@/current"
        watchChanges: true
        onLoaded: root.selected = text().trim()
        onFileChanged: reload()
        onLoadFailed: root.selected = ""
    }
    Variants {
        model: Quickshell.screens
        Scope {
            id: output
            required property var modelData
        PanelWindow {
            screen: output.modelData
            visible: root.selected === "pixel"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "rice-pixel-desktop"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: "transparent"
            mask: Region {}
            PixelLockVisual { showClock: true }
        }
        PanelWindow {
            screen: output.modelData
            visible: root.selected === "pixel" && root.popup !== ""
            anchors { top: true; right: true }
            implicitWidth: Math.min(620, output.modelData.width - 24)
            implicitHeight: Math.min(490, output.modelData.height - 48)
            margins { top: 27; right: 6 }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "rice-pixel-popup"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"
            mask: Region { item: popupContent }
            Item {
                id: popupContent
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.popup = ""
                PixelWidgets {
                    enabledForProfile: root.selected === "pixel" && (root.popup === "system" || root.popup === "ram")
                    popupMode: root.popup
                }
                PixelControls {
                    mode: root.popup
                    backend: "@STUDIO_APP@/themes/extras/pixel/backend.py"
                    live: root.selected === "pixel"
                }
                Rectangle {
                    anchors.right: parent.right; anchors.top: parent.top
                    anchors.rightMargin: 18; anchors.topMargin: 5
                    width: 22; height: 22; color: dismiss.containsMouse ? "#33332d" : "#101010"
                    Text { anchors.centerIn: parent; text: "×"; color: "#c9c8c0" }
                    MouseArea { id: dismiss; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.popup = "" }
                }
            }
        }
        }
    }
}
