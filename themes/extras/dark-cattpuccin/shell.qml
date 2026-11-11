import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
ShellRoot {
    id: root
    property bool opened: false
    property string query: ""
    property var apps: {
        let q=query.toLowerCase();
        return DesktopEntries.applications.values.filter(a=>!a.noDisplay && (!q || (a.name+" "+a.genericName).toLowerCase().includes(q))).sort((a,b)=>a.name.localeCompare(b.name));
    }
    function launch() {
        if(root.apps.length && results.currentIndex>=0)root.apps[results.currentIndex].execute();
        root.opened=false;
    }
    IpcHandler { target: "launcher";function toggle(): void {root.opened=!root.opened;if(root.opened){root.query="";results.currentIndex=0;search.forceActiveFocus();}} }
    PanelWindow {
        visible: root.opened
        implicitWidth: 420;implicitHeight: 320
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "dark-cattpuccin-launcher"
        color: "#11111b"
        Rectangle {
            anchors.fill: parent;color: "#11111b";border.width: 3;border.color: "#9399b2";radius: 16
            Row {
                id: header;x: 2;y: 2;width: parent.width-4;height: 44
                Rectangle { width: 62;height: 44;color: "#9399b2";Text {anchors.centerIn: parent;text: "drun";color: "#11111b";font.family: "JetBrainsMono Nerd Font Mono";font.pixelSize: 14;font.bold: true} }
                Rectangle {
                    width: parent.width-62;height: 44;color: "#181825"
                    Text { x: 15;anchors.verticalCenter: parent.verticalCenter;text: "Type to search...";visible: search.text==="";color: "#858585";font.family: "JetBrainsMono Nerd Font Mono";font.pixelSize: 14;font.bold: true }
                    TextInput {
                        id: search;x: 15;width: parent.width-30;anchors.verticalCenter: parent.verticalCenter
                        color: "#cdd6f4";font.family: "JetBrainsMono Nerd Font Mono";font.pixelSize: 14;font.bold: true;focus: true;selectByMouse: true
                        text: root.query;onTextEdited: {root.query=text;results.currentIndex=0;}
                        Keys.onEscapePressed: root.opened=false
                        Keys.onReturnPressed: root.launch()
                        Keys.onDownPressed: results.currentIndex=Math.min(root.apps.length-1,results.currentIndex+1)
                        Keys.onUpPressed: results.currentIndex=Math.max(0,results.currentIndex-1)
                        Keys.onTabPressed: results.currentIndex=(results.currentIndex+1)%Math.max(1,root.apps.length)
                    }
                }
            }
            ListView {
                id: results;x: 2;y: 46;width: parent.width-4;height: parent.height-48;clip: true
                model: root.apps;currentIndex: 0;boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: results.width;height: 39
                    readonly property bool chosen: results.currentIndex===index
                    color: chosen ? "#9399b2" : (index%2===0 ? "#11111b":"#181825")
                    Row {
                        x: 15;anchors.verticalCenter: parent.verticalCenter;spacing: 8
                        Text { text: row.modelData.name;color: row.chosen ? "#111111":"#cdd6f4";font.family: "JetBrainsMono Nerd Font Mono";font.pixelSize: 14;font.bold: true }
                        Text {text: row.modelData.genericName ? "("+row.modelData.genericName+")":"";color: row.chosen ? "#555555":"#a6adc8";font.family: "JetBrainsMono Nerd Font Mono";font.pixelSize: 12;font.italic: true}
                    }
                    MouseArea {anchors.fill: parent;hoverEnabled: true;onPositionChanged: results.currentIndex=row.index;onClicked: {results.currentIndex=row.index;root.launch();}}
                }
                Text { anchors.centerIn: parent;visible: root.apps.length===0;text: "No matching applications";color: "#999999";font.family: "JetBrainsMono Nerd Font Mono" }
            }
        }
    }
}
