import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Item {
 id:page;required property var studio
 ColumnLayout {anchors.fill:parent;spacing:16
  RowLayout {Layout.fillWidth:true;Text {text:"Under the hood.";font.family:"C059";font.pixelSize:34;color:"#eee7dc"} Item {Layout.fillWidth:true} ActionButton {text:"Check again";onClicked:page.studio.request("health",{},"Checking installed tools")}}
  Text {Layout.fillWidth:true;wrapMode:Text.Wrap;text:"This machine’s capabilities. The Serpantinum bar hook allows a theme bar to take over while its preset is active.";color:"#aaa49a";font.family:"JetBrains Mono";font.pixelSize:12}
  ListView {Layout.fillWidth:true;Layout.fillHeight:true;clip:true;spacing:1;model:page.studio.library.health || []
   delegate:Rectangle {required property var modelData;required property int index;width:ListView.view.width;height:58;color:index%2 ? "#18191c":"#141518"
    RowLayout {anchors.fill:parent;anchors.margins:16;spacing:20
     Text {text:modelData.ok ? "✓":"×";color:modelData.ok ? "#aec7aa":"#e0a28c";font.pixelSize:20}
     Text {text:modelData.name;Layout.preferredWidth:150;color:"#e4ddd2";font.family:"JetBrains Mono";font.pixelSize:13}
     Text {text:modelData.detail;Layout.fillWidth:true;elide:Text.ElideMiddle;color:"#8c8890";font.family:"JetBrains Mono";font.pixelSize:11}
    }
   }
  }
  Rectangle {Layout.fillWidth:true;Layout.preferredHeight:94;Layout.bottomMargin:16;color:"#20201e";border.color:"#51483d"
   Column {anchors.fill:parent;anchors.margins:17;spacing:9
    Text {text:"RECOVERY IS PART OF THE WORKFLOW";color:"#d6ab7d";font.family:"JetBrains Mono";font.pixelSize:11}
    Text {width:parent.width;wrapMode:Text.Wrap;text:"Preview uses an independent rollback timer. Save a checkpoint before experimenting. Main stays protected; clone it to edit.";color:"#b7b0a5";font.pixelSize:13}
   }
  }
 }
}
