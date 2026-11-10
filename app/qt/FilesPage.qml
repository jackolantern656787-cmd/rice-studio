import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ScrollView {
    id:page
    required property var studio
    clip:true;contentWidth:availableWidth
    ColumnLayout {width:page.availableWidth-8;spacing:14
        Text {textFormat:Text.PlainText;text:"Configuration files";font.family:"C059";font.pixelSize:23;font.weight:Font.Normal;color:"#ddddde"}
        Text {textFormat:Text.PlainText;Layout.fillWidth:true;wrapMode:Text.Wrap;text:"Open the selected preset’s full configuration in your editor. Create a checkpoint first—external edits aren’t tracked automatically.";font.pixelSize:12;color:"#99999a"}
        ActionButton {text:"+ Create a checkpoint first";onClicked:page.studio.request("checkpoint",{},"Saving a checkpoint")}
        Repeater {model:[{kind:"profiles",title:"Desktop presets",detail:"Wallpaper, palette and component choices"},{kind:"widgets",title:"Widget layouts",detail:"Positions, sizes, visibility and notes"},{kind:"bar",title:"Waybar configuration",detail:"Modules, data sources and click actions"},{kind:"css",title:"Waybar stylesheet",detail:"Typography, spacing and hover styling"},{kind:"terminal",title:"Terminal palette",detail:"Colors, font and opacity"}]
            Rectangle {required property var modelData;Layout.fillWidth:true;Layout.preferredHeight:90;radius:0;color:"#19191a";border.color:"#353536"
                Column {x:17;anchors.verticalCenter:parent.verticalCenter;spacing:8;Text {textFormat:Text.PlainText;text:modelData.title;color:"#dbdbdc";font.pixelSize:15;font.weight:Font.DemiBold} Text {textFormat:Text.PlainText;text:modelData.detail;color:"#99999a";font.pixelSize:11}}
                ActionButton {anchors.right:parent.right;anchors.verticalCenter:parent.verticalCenter;anchors.rightMargin:16;text:"Open ↗";onClicked:page.studio.request("open_config",{key:page.studio.selectedKey,kind:modelData.kind},"",true)}
            }
        }
        Text {textFormat:Text.PlainText;Layout.fillWidth:true;Layout.topMargin:10;Layout.bottomMargin:22;wrapMode:Text.Wrap;text:"Emergency recovery: rice-studio-recover. Your original desktop configuration files are never replaced.";font.family:"JetBrains Mono";font.pixelSize:10;color:"#818182"}
    }
}
