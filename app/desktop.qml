import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
ShellRoot {
 id:root
 property string selected:"main"
 property var profiles:({})
 readonly property var preset:profiles[selected] || ({})
 readonly property string rice:preset.rice || ""
 readonly property string bar:preset.bar || ""
 readonly property string base:Quickshell.env("HOME")+"/.local/share/rice-studio-portable/themes"
 readonly property bool packed:selected!=="main" && rice!==""
 Variants {
  model:root.packed && root.bar!=="main" && root.bar!=="studio" && root.bar!=="serashell" ? [root.bar] : []
  delegate:Process {
   required property string modelData
   command:["waybar","-c",root.base+"/bars/"+modelData+"/config.jsonc","-s",root.base+"/bars/"+modelData+"/style.css"]
   running:true
  }
 }
 Variants {
  model:root.packed ? (root.bar==="serashell" ? ["serashell"] : ["pixel","dark-grey","dark-cattpuccin","fuji-dusk","cold-front","honeyveil","teigu","tideglass"].includes(root.rice) ? [root.rice] : []) : []
  delegate:Process {
   required property string modelData
   command:["quickshell","-n","-p",root.base+"/extras/"+modelData+"/shell.qml"]
   running:true
  }
 }
 readonly property var palette:(preset.theme || {}).colors || ({base:"#17191d",text:"#eee7dc",blue:"#d6ab7d"})
 property date now:new Date()
 FileView {path:Quickshell.env("HOME")+"/.local/state/rice-studio-portable/current";watchChanges:true;onLoaded:root.selected=text().trim();onFileChanged:reload()}
 FileView {path:Quickshell.env("HOME")+"/.config/rice-studio-portable/profiles.json";watchChanges:true;onLoaded:{try{root.profiles=JSON.parse(text())}catch(e){}}onFileChanged:reload()}
 Timer {interval:1000;running:root.selected!=="main";repeat:true;onTriggered:root.now=new Date()}
 Variants {
  model:Quickshell.screens
  PanelWindow {
   required property var modelData
   screen:modelData;visible:root.selected!=="main"
   anchors {top:true;bottom:true;left:true;right:true}
   exclusionMode:ExclusionMode.Ignore
   WlrLayershell.layer:WlrLayer.Background
   WlrLayershell.namespace:"rice-studio-portable-wallpaper"
   WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
   color:root.palette.base
   Image {anchors.fill:parent;source:root.preset.wallpaper ? "file://"+root.preset.wallpaper:"";fillMode:Image.PreserveAspectCrop;asynchronous:true}
  }
 }
 Variants {
  model:Quickshell.screens
  PanelWindow {
   required property var modelData
   screen:modelData;visible:root.selected!=="main" && (!root.packed || root.bar==="studio")
   anchors {top:true;left:true;right:true}
   implicitHeight:30;exclusionMode:ExclusionMode.Ignore
   WlrLayershell.layer:WlrLayer.Top
   WlrLayershell.namespace:"rice-studio-portable-bar"
   WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
   color:root.palette.base
   Rectangle {anchors.bottom:parent.bottom;width:parent.width;height:1;color:root.palette.blue}
   Row {x:12;anchors.verticalCenter:parent.verticalCenter;spacing:4
    Repeater {model:6
     Rectangle {required property int index;width:27;height:23;color:workspaceHover.containsMouse ? root.palette.blue:root.palette.base
      Text {anchors.centerIn:parent;text:parent.index+1;color:workspaceHover.containsMouse ? root.palette.base:root.palette.text;font.family:(root.preset.theme || {}).fontFamily || "JetBrains Mono";font.pixelSize:12}
      MouseArea {id:workspaceHover;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:workspace.command=["python3",Quickshell.env("HOME")+"/.local/share/rice-studio-portable/command.py","workspace",String(parent.index+1)];onReleased:workspace.running=true}
     }
    }
   }
   Text {anchors.centerIn:parent;text:root.preset.label ? root.preset.label.split("·")[0].trim():"Rice Studio";color:root.palette.text;font.family:(root.preset.theme || {}).fontFamily || "JetBrains Mono";font.pixelSize:12}
   Text {anchors.right:parent.right;anchors.rightMargin:16;anchors.verticalCenter:parent.verticalCenter;text:Qt.formatDateTime(root.now,"ddd  HH:mm");font.family:(root.preset.theme || {}).fontFamily || "JetBrains Mono";font.pixelSize:12;color:root.palette.text}
  }
 }
 Process {id:workspace}
}
