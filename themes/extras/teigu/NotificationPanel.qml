import QtQuick
import QtQuick.Controls
import Quickshell.Io

Rectangle {
    id: panel
    required property string mode
    required property string backend
    property var payload: ({rows: []})
    property string errorText: ""
    property var actions: []
    property bool live: visible
    x: 10; y: 40; width: parent.width-20; height: parent.height-48
    visible: ["audio","network","notifications"].indexOf(mode)>=0
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 140 } }
    color: "#e6101112"; border.color: "#68656b"; border.width: 1
    function refresh() { if(!fetch.running) { fetch.command=["python3",backend,mode];fetch.running=true; } }
    function act(kind,value) { actions.push(["python3",backend,"action",kind,String(value===undefined ? "" : value)]);nextAction(); }
    function nextAction() { if(!mutate.running && actions.length) { mutate.command=actions.shift();mutate.running=true; } }
    onModeChanged: { payload={rows:[]};errorText="";if(visible)refresh(); }
    onVisibleChanged: if(visible)refresh()
    Timer { interval: 3000; running: panel.visible && panel.live; repeat: true; triggeredOnStart: true; onTriggered: panel.refresh() }
    Process {
        id: fetch
        stdout: StdioCollector { onStreamFinished: { try { let d=JSON.parse(text);if(d.error)panel.errorText=d.error;else {panel.payload=d;panel.errorText="";} } catch(e) {panel.errorText="Could not read panel data";} } }
    }
    Process {
        id: mutate
        stdout: StdioCollector { onStreamFinished: { try { let d=JSON.parse(text);panel.errorText=d.error || ""; }catch(e){} } }
        onExited: { panel.refresh();panel.nextAction(); }
    }
    component PixelButton: Rectangle {
        property string label
        signal clicked()
        width: labelText.implicitWidth+24; height: 32
        color: click.containsMouse ? "#33332d" : "#20201d";border.color: "#505048";border.width: 1
        Text { id: labelText; anchors.centerIn: parent;text: parent.label;color: "#d1d0c6";font.family: "Iosevka Nerd Font";font.pixelSize: 13 }
        MouseArea { id: click;anchors.fill: parent;hoverEnabled: true;cursorShape: Qt.PointingHandCursor;onClicked: parent.clicked() }
        Accessible.role: Accessible.Button;Accessible.name: label
        activeFocusOnTab: true
        Keys.onReturnPressed: clicked()
        Keys.onSpacePressed: clicked()
    }
    Column {
        x: 16;y: 14;width: parent.width-32;spacing: 12
        Text { text: panel.mode.toUpperCase();color: "#d0d8d4";font.family: "Iosevka Nerd Font";font.pixelSize: 20;font.bold: true }
        Rectangle { width: parent.width;height: 1;color: "#3a3a34" }
        Row {
            spacing: 10;visible: panel.mode==="audio"
            PixelButton { label: panel.payload.muted ? "UNMUTE" : "MUTE";onClicked: panel.act("mute") }
            Text { text: Math.round(panel.payload.volume || 0)+"%";color: "#c4ceca";font.family: "Iosevka Nerd Font";font.pixelSize: 15;anchors.verticalCenter: parent.verticalCenter }
            Slider {
                id: volume;from: 0;to: 100;stepSize: 1;width: 280
                value: panel.payload.volume || 0
                onPressedChanged: if(!pressed)panel.act("volume",value)
                background: Rectangle { x: volume.leftPadding;y: volume.topPadding+volume.availableHeight/2-3;width: volume.availableWidth;height: 6;color: "#393932"
                    Rectangle { width: volume.visualPosition*parent.width;height: parent.height;color: "#bdbdb2" }
                }
                handle: Rectangle { x: volume.leftPadding+volume.visualPosition*(volume.availableWidth-width);y: volume.topPadding+volume.availableHeight/2-height/2;width: 10;height: 18;color: "#d1d1c7";border.color: "#707067" }
                Accessible.name: "Output volume"
            }
        }
        Row {
            spacing: 10;visible: panel.mode==="network"
            PixelButton { label: panel.payload.wifi==="enabled" ? "WI-FI OFF" : "WI-FI ON";onClicked: panel.act("wifi",panel.payload.wifi==="enabled" ? "off":"on") }
            PixelButton { label: "CONNECTIONS…";onClicked: panel.act("network-editor") }
        }
        Row {
            spacing: 10;visible: panel.mode==="notifications"
            PixelButton { label: panel.payload.dnd ? "DND ON" : "DND OFF";onClicked: panel.act("dnd") }
            PixelButton { label: "CLEAR ALL";onClicked: panel.act("clear") }
        }
        Text { visible: panel.mode==="network";width: parent.width;text: panel.payload.status || "";color: "#929289";font.family: "Iosevka Nerd Font";font.pixelSize: 12;wrapMode: Text.Wrap }
        Text { visible: panel.errorText!=="";width: parent.width;text: panel.errorText;color: "#dfbaaa";font.family: "Iosevka Nerd Font";font.pixelSize: 12;wrapMode: Text.Wrap;textFormat: Text.PlainText }
        Text { visible: (panel.payload.rows || []).length===0 && !panel.errorText;width: parent.width;text: panel.mode==="notifications" ? "All quiet. Nothing here." : "No devices or saved connections found.";color: "#929289";font.family: "Iosevka Nerd Font" }
        ListView {
            width: parent.width;height: Math.max(100,panel.height-parent.y-180);clip: true;spacing: 7
            model: panel.payload.rows || []
            delegate: Rectangle {
                id: card
                required property var modelData
                width: ListView.view.width;height: panel.mode==="notifications" ? Math.max(80,notice.implicitHeight+22) : 43
                color: modelData.active ? "#2d2d27" : "#181816";border.color: "#3a3a34";border.width: 1
                Text { x: 12;anchors.verticalCenter: parent.verticalCenter;width: parent.width-24;visible: panel.mode!=="notifications";text: (card.modelData.active ? "■ " : "□ ")+card.modelData.label;color: "#c4ceca";font.family: "Iosevka Nerd Font";font.pixelSize: 14;elide: Text.ElideRight;textFormat: Text.PlainText }
                Column {
                    id: notice;x: 12;y: 10;width: parent.width-60;spacing: 4;visible: panel.mode==="notifications"
                    Text { width: parent.width;text: card.modelData.app || "";color: "#85857c";font.family: "Iosevka Nerd Font";font.pixelSize: 11;textFormat: Text.PlainText }
                    Text { width: parent.width;text: card.modelData.summary || "";color: "#d0d0c6";font.family: "Iosevka Nerd Font";font.pixelSize: 14;wrapMode: Text.Wrap;textFormat: Text.PlainText }
                    Text { width: parent.width;text: card.modelData.body || "";color: "#aaa99f";font.family: "Iosevka Nerd Font";font.pixelSize: 12;wrapMode: Text.Wrap;textFormat: Text.PlainText;maximumLineCount: 4;elide: Text.ElideRight }
                }
                MouseArea { anchors.fill: parent;enabled: panel.mode!=="notifications";cursorShape: Qt.PointingHandCursor;onClicked: panel.act(panel.mode==="audio" ? "output":"connect",card.modelData.value) }
                PixelButton { anchors.right: parent.right;anchors.top: parent.top;anchors.margins: 6;visible: panel.mode==="notifications";label: "×";onClicked: panel.act("dismiss",card.modelData.uid) }
            }
            ScrollBar.vertical: ScrollBar {}
        }
    }
}
