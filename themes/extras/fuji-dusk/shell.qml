import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
ShellRoot {
    id: root
    FontLoader { id: weekdayFont; source: "" }
    property string selected: ""
    FileView {
        path: "@STUDIO_STATE@/current"
        watchChanges: true
        onLoaded: root.selected=text().trim()
        onFileChanged: reload()
        onLoadFailed: root.selected=""
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.selected==="fuji-dusk"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "fuji-dusk-clock"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: "transparent"
            mask: Region {}
            Item {
                id: clock
                anchors.fill: parent
                property date now: new Date()
                readonly property real u: width/1080
                Timer { interval: 1000;running: root.selected==="fuji-dusk";repeat: true;onTriggered: {clock.now=new Date();} }
                Text {
                    id: day
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 94*clock.u
                    text: Qt.formatDateTime(clock.now,"dddd").toUpperCase()
                    font.family: weekdayFont.name
                    font.pixelSize: 42*clock.u
                    font.weight: Font.Normal
                    font.letterSpacing: 4*clock.u
                    color: "#f4f6fc"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter;y: 146*clock.u
                    text: Qt.formatDateTime(clock.now,"dd MMM yyyy").toUpperCase()
                    font.family: "Noto Sans";font.pixelSize: 11*clock.u;font.letterSpacing: 1.8*clock.u;color: "#f4f6fc"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter;y: 164*clock.u
                    text: "- "+Qt.formatDateTime(clock.now,"hh:mm AP")+" -"
                    font.family: "Noto Sans";font.pixelSize: 11*clock.u;font.letterSpacing: 1.3*clock.u;color: "#f4f6fc"
                }
            }
        }
    }
}
