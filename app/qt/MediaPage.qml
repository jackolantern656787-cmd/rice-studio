import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtQuick.Dialogs
import QtQuick.Window
Item {
 id:page;required property var studio
 property var chosen:null
 property var media:(studio.library.media || {})[studio.selectedKey] || []
 onMediaChanged:{chosen=media.length ? media[0]:null;}
 MediaPlayer {id:player;source:page.chosen && page.chosen.video ? page.chosen.url:"";videoOutput:video;loops:MediaPlayer.Infinite;onSourceChanged:if(source.toString()!=="")play();}
 FileDialog {id:importDialog;parentWindow:page.Window.window;title:"Import a preset preview";nameFilters:["Images and video (*.png *.jpg *.jpeg *.webp *.mp4 *.webm)"];onAccepted:page.studio.request("import_media",{key:page.studio.selectedKey,path:decodeURIComponent(selectedFile.toString().replace(/^file:\/\//,""))},"Importing preview")}
 onVisibleChanged:if(!visible)player.pause();else if(chosen && chosen.video)player.play()
 ColumnLayout {
  anchors.fill:parent;spacing:14
  RowLayout {Layout.fillWidth:true
   Column {spacing:6;Text {text:"A rice in motion.";font.family:"C059";font.pixelSize:34;color:"#eee7dc"} Text {text:"Real captures, saved locally. No uploads.";font.family:"JetBrains Mono";font.pixelSize:11;color:"#88878b"}}
   Item {Layout.fillWidth:true}
   ActionButton {text:"Import";onClicked:importDialog.open()}
   ActionButton {text:"Take screenshot";enabled:page.studio.selectedKey===page.studio.library.current && !page.studio.busy && !page.studio.captureCountdown;onClicked:page.studio.capture(false)}
   ActionButton {text:"Record 8s";primary:true;enabled:page.studio.selectedKey===page.studio.library.current && !page.studio.busy && !page.studio.captureCountdown;onClicked:page.studio.capture(true)}
  }
  Text {Layout.fillWidth:true;wrapMode:Text.Wrap;text:"Captures the focused monitor after a 3-second countdown. Rice Studio hides during capture. Close private windows first. Recording is silent.";font.family:"JetBrains Mono";font.pixelSize:11;color:"#aaa49a"}
  Rectangle {Layout.fillWidth:true;Layout.fillHeight:true;color:"#0b0c0e";border.color:"#343438"
   Image {anchors.fill:parent;anchors.margins:1;source:page.chosen && !page.chosen.video ? page.chosen.url:"";fillMode:Image.PreserveAspectFit;asynchronous:true}
   VideoOutput {id:video;anchors.fill:parent;visible:page.chosen && page.chosen.video;fillMode:VideoOutput.PreserveAspectFit}
   Column {visible:!page.chosen;anchors.centerIn:parent;spacing:12
    Text {anchors.horizontalCenter:parent.horizontalCenter;text:"Nothing staged yet.";font.family:"C059";font.pixelSize:30;color:"#bcb2a5"}
    Text {text:"Capture the active desktop to build your preview reel.";font.family:"JetBrains Mono";font.pixelSize:11;color:"#77747c"}
   }
   ActionButton {visible:page.chosen && page.chosen.video;anchors.bottom:parent.bottom;anchors.right:parent.right;anchors.margins:15;text:player.playbackState===MediaPlayer.PlayingState ? "Pause":"Play";onClicked:player.playbackState===MediaPlayer.PlayingState ? player.pause():player.play()}
  }
  ListView {Layout.fillWidth:true;Layout.preferredHeight:52;Layout.bottomMargin:14;orientation:ListView.Horizontal;spacing:8;clip:true;model:page.media
   delegate:ActionButton {required property var modelData;text:(modelData.video ? "▶ ":"▧ ")+modelData.name.split('-').slice(0,2).join(' · ');primary:page.chosen===modelData;onClicked:page.chosen=modelData}
  }
 }
}
