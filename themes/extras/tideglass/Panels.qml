import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
Item {
 id:root
 required property var controller
 property string mode:""
 property string shownMode:""
 property real reveal:mode!=="" ? 1:0
 Behavior on reveal {NumberAnimation {duration:root.controller.reducedMotion ? 0:220;easing.type:Easing.OutCubic}}
 property string query:""
 property string monitorName:""
 property int index:0
 property var walls:[]
 property string errorText:""
 property bool applying:false
 property string wallpaper:"@STUDIO_APP@/themes/extras/tideglass/wallpaper.jpg"
 readonly property var apps:DesktopEntries.applications.values.filter(e=>!e.noDisplay && (e.name+' '+e.genericName).toLowerCase().includes(query.toLowerCase())).sort((a,b)=>a.name.localeCompare(b.name))
 readonly property real uiScale:Math.min(1,window.width/1280,window.height/800)
 readonly property var filteredWalls:walls.filter(w=>w.name.toLowerCase().includes(query.toLowerCase()))
 FileView {path:"@STUDIO_CONFIG@/profiles.json";watchChanges:true;onLoaded:{try{root.wallpaper=JSON.parse(text()).tideglass.wallpaper;}catch(e){}}onFileChanged:reload()}
 Component.onCompleted:if(mode==="wallpapers")catalog.running=true
 onModeChanged:{if(mode!==""){controller.dismissSystemPanels();shownMode=mode;}query="";index=0;errorText="";if(mode==="wallpapers" && !catalog.running)catalog.running=true;Qt.callLater(()=>{if(mode==="wallpapers")panel.forceActiveFocus();else search.forceActiveFocus();});}
 Connections {target:root.controller;function onActiveChanged(){if(!root.controller.active)root.mode="";}}
 function toggle(value){if(!controller.active)return;if(mode===value){mode="";return;}pendingMode=value;monitor.running=true;}
 property string pendingMode:""
 Process {id:monitor;command:["hyprctl","activeworkspace","-j"];stdout:StdioCollector {onStreamFinished:{try{root.monitorName=JSON.parse(text).monitor || "";}catch(e){}root.mode=root.pendingMode;}}}
 Process {id:catalog;command:["python3","@STUDIO_APP@/themes/extras/tideglass/wallpapers.py"];stdout:StdioCollector {onStreamFinished:{try{let d=JSON.parse(text);root.walls=d.rows || [];root.errorText=d.error || "";}catch(e){root.errorText="Could not read wallpaper gallery";}}}}
 Process {id:change;stdout:StdioCollector {onStreamFinished:{root.applying=false;try{let d=JSON.parse(text);if(d.error)root.errorText=d.error;else root.mode="";}catch(e){root.errorText="Could not apply wallpaper";}}}onExited:root.applying=false}
 function activate(i){if(mode==="launcher"){if(apps[i]){apps[i].execute();mode="";}}else if(filteredWalls[i] && !applying){applying=true;errorText="";change.command=["python3","@STUDIO_APP@/themes/extras/tideglass/wallpapers.py","apply",filteredWalls[i].path];change.running=true;}}
 IpcHandler {target:"launcher";function toggle():void {root.toggle("launcher");}}
 IpcHandler {target:"wallpapers";function toggle():void {root.toggle("wallpapers");}}
 PanelWindow {
  id:window
  visible:root.controller.active && (root.mode!=="" || root.reveal>.001)
  screen:Quickshell.screens.find(s=>s.name===root.monitorName) || Quickshell.screens[0]
  anchors {top:true;bottom:true;left:true;right:true}
  exclusionMode:ExclusionMode.Ignore
  WlrLayershell.layer:WlrLayer.Overlay
  WlrLayershell.keyboardFocus:root.mode!=="" ? WlrKeyboardFocus.Exclusive:WlrKeyboardFocus.None
  WlrLayershell.namespace:"tideglass-picker"
  color:"transparent"
  Image {id:background;anchors.fill:parent;source:"file://"+root.wallpaper;fillMode:Image.PreserveAspectCrop;visible:root.shownMode==="wallpapers";opacity:root.reveal;layer.enabled:true;layer.effect:MultiEffect {blurEnabled:true;blurMax:64;blur:root.reveal;brightness:-.12}}
  MouseArea {anchors.fill:parent;onClicked:if(!root.applying)root.mode="";}
  Rectangle {
   id:panel
   anchors.centerIn:parent;width:root.shownMode==="wallpapers" ? Math.min(1100,window.width-48):Math.min(620,window.width-48);height:root.shownMode==="wallpapers" ? Math.min(750,window.height-48):Math.min(520,window.height-48)
   color:root.shownMode==="wallpapers" ? "#dc4b4f27":"#de1e2939";radius:root.shownMode==="wallpapers" ? 16:14;border.width:1;border.color:root.shownMode==="wallpapers" ? "#665b6038":"#5948576d"
   opacity:root.reveal
   scale:0.97+root.reveal*0.03
   focus:root.shownMode==="wallpapers"
   Keys.onEscapePressed:if(!root.applying)root.mode=""
   Keys.onReturnPressed:if(root.shownMode==="wallpapers")root.activate(root.index)
   Keys.onRightPressed:if(root.shownMode==="wallpapers")root.index=Math.min(root.filteredWalls.length-1,root.index+1)
   Keys.onLeftPressed:if(root.shownMode==="wallpapers")root.index=Math.max(0,root.index-1)
   Keys.onDownPressed:if(root.shownMode==="wallpapers")root.index=Math.min(root.filteredWalls.length-1,root.index+5)
   Keys.onUpPressed:if(root.shownMode==="wallpapers")root.index=Math.max(0,root.index-5)
   MouseArea {anchors.fill:parent;onClicked:if(root.shownMode==="wallpapers")panel.forceActiveFocus();else search.forceActiveFocus()}
   Text {x:20;y:19;visible:root.shownMode==="wallpapers";text:"Very basic wall picker";font.family:"Noto Sans";font.bold:true;font.pixelSize:17;color:"#c5c9d9"}
   Text {visible:root.shownMode==="wallpapers";anchors.right:refresh.left;anchors.rightMargin:8;y:23;text:root.walls.length+" images";font.family:"Noto Sans";font.pixelSize:11;color:"#bec0b0"}
   Rectangle {id:refresh;visible:root.shownMode==="wallpapers";anchors.right:closeGallery.left;anchors.rightMargin:6;y:17;width:80;height:26;radius:2;color:"#d3d0b6";Text {anchors.centerIn:parent;text:"Refresh";font.family:"Noto Sans";font.pixelSize:11;color:"#464a30"}MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:if(!catalog.running)catalog.running=true}}
   Rectangle {id:closeGallery;visible:root.shownMode==="wallpapers";anchors.right:parent.right;anchors.rightMargin:20;y:17;width:80;height:26;radius:2;color:"#d3d0b6";Text {anchors.centerIn:parent;text:"×";font.family:"Noto Sans";font.pixelSize:14;color:"#464a30"}MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:if(!root.applying)root.mode=""}}
   Rectangle {
    id:searchBox;visible:root.shownMode==="launcher";x:18;y:root.shownMode==="wallpapers" ? 43:18;width:parent.width-36;height:root.shownMode==="wallpapers" ? 30:44;radius:5;color:root.shownMode==="wallpapers" ? "#555d604c":"#74516b9c"
    Text {x:12;anchors.verticalCenter:parent.verticalCenter;text:"";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:14;color:"#bfc4e2"}
    TextInput {id:search;x:36;width:parent.width-48;anchors.verticalCenter:parent.verticalCenter;color:"#e0e1ef";font.family:"Noto Sans";font.pixelSize:14;focus:true;text:root.query;onTextEdited:{root.query=text;root.index=0;}
     Text {visible:!search.text;text:root.shownMode==="wallpapers" ? "Filter wallpapers…":"Search...";font:search.font;color:"#b8bfd8"}
     Keys.onEscapePressed:if(!root.applying)root.mode=""
     Keys.onReturnPressed:root.activate(root.index)
     Keys.onRightPressed:root.index=Math.min((root.shownMode==="launcher" ? root.apps.length:root.filteredWalls.length)-1,root.index+1)
     Keys.onLeftPressed:root.index=Math.max(0,root.index-1)
     Keys.onDownPressed:root.index=Math.min((root.shownMode==="launcher" ? root.apps.length:root.filteredWalls.length)-1,root.index+5)
     Keys.onUpPressed:root.index=Math.max(0,root.index-5)
    }
   }
   Rectangle {id:clipboard;x:18;y:72;width:parent.width-36;height:44;visible:root.shownMode==="launcher";color:"#202f3a4d";border.color:"#385c6d86";radius:3
    Text {x:12;anchors.verticalCenter:parent.verticalCenter;text:"󰅌  Last clipboard";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:11;color:"#aebbd3"}
    Text {anchors.right:parent.right;anchors.rightMargin:12;anchors.verticalCenter:parent.verticalCenter;text:"History ↗";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:10;color:"#bdb7d8"}
    MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{root.mode="";Quickshell.execDetached(["@STUDIO_APP@/commands/serpantinum","msg","toggle","clipboard"]);}}
   }
   GridView {
    id:grid;x:18;y:root.shownMode==="wallpapers" ? 64:130;width:parent.width-36;height:parent.height-y-30;clip:true
    cellWidth:width/5;cellHeight:root.shownMode==="wallpapers" ? cellWidth*9/16+8:96
    model:root.shownMode==="wallpapers" ? root.filteredWalls:root.apps;currentIndex:root.index
    onCurrentIndexChanged:positionViewAtIndex(currentIndex,GridView.Contain)
    delegate:Rectangle {
     id:tile;required property var modelData;required property int index;width:grid.cellWidth-10;height:grid.cellHeight-8;radius:root.shownMode==="wallpapers" ? 1:5
     color:root.index===index ? (root.shownMode==="wallpapers" ? "#797e7858":"#67586487"):"transparent";border.width:root.index===index ? 1:0;border.color:"#a3b2cf"
     Image {anchors.horizontalCenter:parent.horizontalCenter;y:root.shownMode==="wallpapers" ? 3:10;width:root.shownMode==="wallpapers" ? parent.width-6:40;height:root.shownMode==="wallpapers" ? (parent.width-6)*9/16:40;fillMode:root.shownMode==="wallpapers" ? Image.PreserveAspectCrop:Image.PreserveAspectFit;source:root.shownMode==="wallpapers" ? tile.modelData.preview:Quickshell.iconPath(tile.modelData.icon || "application-x-executable");onStatusChanged:if(status===Image.Error && root.shownMode==="launcher")source=Quickshell.iconPath("application-x-executable");asynchronous:true;sourceSize:root.shownMode==="wallpapers" ? Qt.size(320,180):Qt.size(40,40)}
     Text {visible:root.shownMode!=="wallpapers";anchors.bottom:parent.bottom;anchors.bottomMargin:7;anchors.horizontalCenter:parent.horizontalCenter;width:parent.width-10;text:tile.modelData.name;textFormat:Text.PlainText;elide:Text.ElideRight;horizontalAlignment:Text.AlignHCenter;font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:11;color:"#d6d9e2"}
     MouseArea {anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onEntered:root.index=tile.index;onClicked:root.activate(tile.index)}
    }
   }
   Text {x:18;anchors.bottom:parent.bottom;anchors.bottomMargin:9;width:parent.width-36;text:root.applying ? "Applying wallpaper…":root.errorText;textFormat:Text.PlainText;elide:Text.ElideRight;color:"#e3bcc6";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:10}
  }
 }
}
