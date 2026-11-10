import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Rectangle {
    id:welcome
    required property var studio
    property bool skipNext:!!studio.library.preferences.skip_welcome
    color:"#101113"
    Rectangle {
        x:parent.width*.51;y:28;width:parent.width*.46;height:parent.height-56;color:"#0b0c0e"
        Image {anchors.fill:parent;source:welcome.studio.selected.image;fillMode:Image.PreserveAspectCrop;asynchronous:true;sourceSize.height:1400}
        Rectangle {anchors.bottom:parent.bottom;width:parent.width;height:50;color:"#eb101113";Text {textFormat:Text.PlainText;x:16;anchors.verticalCenter:parent.verticalCenter;text:welcome.studio.selected.title;font.family:"JetBrains Mono";font.pixelSize:14;color:"#c8c3b9"}}
    }
    Flickable {
        x:parent.width*.055;y:50;width:parent.width*.40;height:parent.height-100
        contentWidth:width;contentHeight:copy.implicitHeight;clip:true;boundsBehavior:Flickable.StopAtBounds
        ColumnLayout {
            id:copy;width:parent.width;spacing:0
            Text {textFormat:Text.PlainText;text:"RICE STUDIO / WORKSHOP 02";font.family:"JetBrains Mono";font.pixelSize:10;font.letterSpacing:2;color:"#747177"}
            Text {textFormat:Text.PlainText;Layout.topMargin:30;text:"Rice\nStudio.";font.family:"C059";font.pixelSize:welcome.width<1050 ? 50:65;lineHeight:.93;color:"#e0dcd3"}
            Rectangle {Layout.topMargin:28;width:36;height:1;color:"#c7aa83"}
            Text {textFormat:Text.PlainText;Layout.topMargin:22;Layout.fillWidth:true;text:"A collection worth\nspending time with.";font.family:"JetBrains Mono";font.pixelSize:18;lineHeight:1.2;color:"#a9a6a0"}
            ActionButton {Layout.topMargin:28;text:"Open collection  →";implicitWidth:205;primary:true;reducedMotion:welcome.studio.reducedMotion;onClicked:welcome.studio.enter()}
            CheckBox {Layout.topMargin:9;text:"Skip this screen next time";checked:welcome.skipNext;onToggled:welcome.skipNext=checked;font.family:"JetBrains Mono";font.pixelSize:12;palette.windowText:"#858287";palette.highlight:"#c7aa83"}
            Text {textFormat:Text.PlainText;Layout.topMargin:24;text:"Built for the details you notice.";font.family:"C059";font.italic:true;font.pixelSize:12;color:"#66636a"}
            Item {Layout.preferredHeight:12}
        }
        ScrollBar.vertical:ScrollBar {width:3}
    }
}
