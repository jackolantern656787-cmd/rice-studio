import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ColumnLayout {
    id:page
    required property var studio
    spacing:16
    RowLayout {Layout.fillWidth:true;Column {spacing:8;Text {textFormat:Text.PlainText;text:"Checkpoints";font.family:"C059";font.pixelSize:23;font.weight:Font.Normal;color:"#ddddde"} Text {textFormat:Text.PlainText;text:"Saved before edits and previews.";font.pixelSize:12;color:"#99999a"}} Item {Layout.fillWidth:true} ActionButton {text:"+ Checkpoint";primary:true;onClicked:page.studio.request("checkpoint",{},"Saving a checkpoint")}}
    ListView {
        id:timeline
        Layout.fillWidth:true;Layout.fillHeight:true;clip:true;spacing:9
        model:page.studio.library.history
        delegate:Rectangle {
            id:entry
            required property var modelData
            width:timeline.width;height:72;radius:0;color:entryMouse.containsMouse ? "#202021":"#19191a";border.color:"#363637"
            Behavior on color {ColorAnimation {duration:page.studio.duration}}
            Rectangle {x:18;anchors.verticalCenter:parent.verticalCenter;width:9;height:9;radius:0;color:entry.modelData.desktop ? "#c7aa83":"#727273"}
            Column {x:44;anchors.verticalCenter:parent.verticalCenter;width:parent.width-180;spacing:7
                Text {textFormat:Text.PlainText;width:parent.width;text:entry.modelData.label;color:"#dcdcdd";font.pixelSize:14;elide:Text.ElideRight}
                Text {textFormat:Text.PlainText;text:entry.modelData.time+"  /  "+(entry.modelData.desktop ? "DESKTOP + FILES":"PRESET FILES");font.family:"JetBrains Mono";font.pixelSize:9;color:"#929293"}
            }
            ActionButton {anchors.right:parent.right;anchors.verticalCenter:parent.verticalCenter;anchors.rightMargin:14;text:"Restore";onClicked:page.studio.ask("Restore this checkpoint?","Your current edits will be checkpointed first. Desktop snapshots also restore the running preset.",function(){page.studio.request("restore",{id:entry.modelData.id},"Restoring the checkpoint");})}
            MouseArea {id:entryMouse;anchors.fill:parent;hoverEnabled:true;acceptedButtons:Qt.NoButton;z:-1}
        }
        Column {anchors.centerIn:parent;visible:timeline.count===0;spacing:12;Text {textFormat:Text.PlainText;anchors.horizontalCenter:parent.horizontalCenter;text:"Nothing to undo yet.";font.pixelSize:20;color:"#c8c8c9"} Text {textFormat:Text.PlainText;text:"Your first save will create a checkpoint.";font.pixelSize:12;color:"#8f8f90"}}
        ScrollBar.vertical:ScrollBar {width:4}
    }
    Rectangle {
        Layout.fillWidth:true;Layout.preferredHeight:112;radius:0;color:"#1c1c1d";border.color:"#3e3e3f"
        Column {x:18;y:18;spacing:9;Text {textFormat:Text.PlainText;text:"Need the original desktop?";font.pixelSize:15;color:"#d8d8d9";font.weight:Font.DemiBold} Text {textFormat:Text.PlainText;text:"Return to your personal pre-install desktop.";font.pixelSize:11;color:"#a2a2a3"}}
        ActionButton {anchors.right:parent.right;anchors.bottom:parent.bottom;anchors.margins:16;text:"Restore personal Main";danger:true;onClicked:page.studio.ask("Return to Main?","This restores your original compositor settings and hides Studio’s desktop layers. Your other presets stay in the collection.",function(){page.studio.request("rescue",{},"Recovering Main");})}
    }
    Text {textFormat:Text.PlainText;Layout.fillWidth:true;Layout.bottomMargin:18;wrapMode:Text.Wrap;text:"Checkpoints cover managed presets and widget layouts. They are not disk images or backups of every app’s configuration.";font.pixelSize:10;color:"#7c7c7d"}
}
