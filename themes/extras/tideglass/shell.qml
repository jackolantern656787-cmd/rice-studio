import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
ShellRoot {
 id:root
 function dismissSystemPanels(){systemPanels.mode="";}
 function dismissOtherPanels(){opened=false;notificationsOpen=false;panels.mode="";}
 Panels {id:panels;controller:root}
 SystemPanels {id:systemPanels;controller:root}
 AnimatedWallpaper {
  controller:root
  videoPath:"@STUDIO_APP@/themes/extras/tideglass/wallpaper-4k.mp4"
  enabled:panels.wallpaper==="@STUDIO_APP@/themes/extras/tideglass/wallpaper.jpg"
 }
 property string selected:""
 readonly property bool active:selected==="tideglass"
 property bool opened:false
 property bool notificationsOpen:false
 property string monitorName:""
 property int choice:0
 property string armed:""
 property bool reducedMotion:false
 property real progress:opened ? 1:0
 property date now:new Date()
 property var stats:({ram:0,detail:"",music:""})
 property real previousTotal:0
 property real previousIdle:0
 property real cpu:0
 property var history:[]
 property var audio:[]
 property var info:({os:"Arch Linux x86_64",kernel:"",cpu:"",gpu:"",board:"",driver:"",uptime:"",shell:""})
 Process {id:systemInfo;command:["python3","@STUDIO_APP@/themes/extras/tideglass/sysinfo.py"];stdout:StdioCollector {onStreamFinished:{try{root.info=JSON.parse(text);}catch(e){}}}}

 readonly property var actions:[{id:"lock",label:"Lock",icon:"󰌾"},{id:"logout",label:"Logout",icon:"󰍃"},{id:"suspend",label:"Suspend",icon:"󰒲"},{id:"reboot",label:"Reboot",icon:"󰜉"},{id:"poweroff",label:"Shutdown",icon:"󰐥"}]
 FontLoader {id:pixel;source:"file://@STUDIO_APP@/themes/extras/pixel/RicePixel.ttf"}
 FileView {path:"@STUDIO_STATE@/current";watchChanges:true;onLoaded:root.selected=text().trim();onFileChanged:reload()}
 FileView {path:"@STUDIO_CONFIG@/studio-ui.json";watchChanges:true;onLoaded:{try{root.reducedMotion=!!JSON.parse(text()).reduce_motion;}catch(e){}}onFileChanged:reload()}
 onActiveChanged:if(!active){opened=false;notificationsOpen=false;}
 Behavior on progress {NumberAnimation {duration:root.reducedMotion ? 0:210;easing.type:Easing.OutCubic}}
 Process {id:metrics;command:["python3","@STUDIO_APP@/metrics.py"];stdout:StdioCollector {onStreamFinished:{try{let d=JSON.parse(text);root.cpu=root.previousTotal && d.total>root.previousTotal ? Math.max(0,100*(1-(d.idle-root.previousIdle)/(d.total-root.previousTotal))):0;root.previousTotal=d.total;root.previousIdle=d.idle;root.stats=d;let a=root.history.slice();a.push(root.cpu);if(a.length>45)a.shift();root.history=a;}catch(e){}}}}
 function pick(index){choice=index;let id=actions[index].id;if(id==="lock"){Quickshell.execDetached(["@STUDIO_APP@/commands/tideglass","--execute",id]);opened=false;}else armed=id;}
 function confirm(){if(armed){Quickshell.execDetached(["@STUDIO_APP@/commands/tideglass","--execute",armed]);opened=false;armed="";}}
 IpcHandler {target:"power";function toggle():void {if(!root.active)return;if(root.opened){root.opened=false;return;}monitor.running=true;}}
 IpcHandler {target:"notifications";function toggle():void {if(root.active){systemPanels.mode="";root.notificationsOpen=!root.notificationsOpen;}}}
 IpcHandler {target:"tideglass";function status():string {return JSON.stringify({active:root.active,powerOpen:root.opened,notificationsOpen:root.notificationsOpen,picker:panels.mode,systemPanel:systemPanels.mode,autoTile:false});}}
 Process {id:monitor;command:["hyprctl","activeworkspace","-j"];stdout:StdioCollector {onStreamFinished:{try{root.monitorName=JSON.parse(text).monitor || "";}catch(e){}panels.mode="";systemPanels.mode="";root.choice=0;root.armed="";root.opened=true;Qt.callLater(()=>keys.forceActiveFocus());}}}
 PanelWindow {
  id:powerWindow
  visible:root.active && (root.opened || root.progress>.001)
  screen:Quickshell.screens.find(s=>s.name===root.monitorName) || Quickshell.screens[0]
  anchors {top:true;bottom:true;left:true;right:true}
  exclusionMode:ExclusionMode.Ignore
  WlrLayershell.layer:WlrLayer.Overlay
  WlrLayershell.keyboardFocus:root.opened ? WlrKeyboardFocus.Exclusive:WlrKeyboardFocus.None
  WlrLayershell.namespace:"tideglass-power"
  color:"transparent"
  Rectangle {anchors.fill:parent;color:"#a0151b28";opacity:root.progress}
  MouseArea {anchors.fill:parent;onClicked:{root.opened=false;root.armed="";}}
  Item {
   id:keys;anchors.fill:parent;focus:true
   Keys.onEscapePressed:{root.opened=false;root.armed="";}
   Keys.onLeftPressed:{root.choice=(root.choice+4)%5;root.armed="";}
   Keys.onRightPressed:{root.choice=(root.choice+1)%5;root.armed="";}
   Keys.onReturnPressed:{if(root.armed)root.confirm();else root.pick(root.choice);}
   Row {
    anchors.centerIn:parent;spacing:Math.max(12,powerWindow.width*.017)
    Repeater {model:root.actions
     Rectangle {
      id:card;required property var modelData;required property int index
      width:Math.min(280,(powerWindow.width*.75-powerWindow.width*.017*4)/5);height:powerWindow.height*.60
      y:(1-root.progress)*(22+index*8)
      opacity:root.progress
      radius:Math.min(20,width*.075);color:root.choice===index ? "#805f5c82":"#382d3444"
      border.width:root.choice===index ? 2:1;border.color:root.choice===index ? "#e0d2ff":"#9699b1"
      scale:root.choice===index ? 1.025:1
      Behavior on color {ColorAnimation {duration:root.reducedMotion ? 0:150}}
      Behavior on scale {NumberAnimation {duration:root.reducedMotion ? 0:150;easing.type:Easing.OutCubic}}
      PowerIcon {anchors.centerIn:parent;width:Math.min(76,card.width*.29);height:width;kind:card.modelData.id;ink:root.choice===card.index ? "#e0c9f7":"#c9bedc"}
      Text {anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:parent.bottom;anchors.bottomMargin:card.height*.10;text:card.modelData.label;font.family:"Noto Sans";font.pixelSize:13;color:"#e1dfee"}
      MouseArea {anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onEntered:{root.choice=card.index;root.armed="";}onClicked:root.pick(card.index)}
     }
    }
   }
   Rectangle {
    anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:parent.bottom;anchors.bottomMargin:Math.max(28,parent.height*.12)
    width:Math.min(parent.width-40,580);height:root.armed ? 64:36;radius:4;color:root.armed ? "#ed252b3a":"transparent";border.width:root.armed ? 1:0;border.color:"#aaa2c0";opacity:root.progress
    Text {anchors.centerIn:parent;visible:false;text:"← → select    Enter open    Esc close";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:11;color:"#d0cadd"}
    Text {x:18;anchors.verticalCenter:parent.verticalCenter;visible:!!root.armed;text:"Confirm "+(root.actions.find(a=>a.id===root.armed) || {}).label+"?";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:13;color:"#e8e1f5"}
    Rectangle {visible:!!root.armed;anchors.right:parent.right;anchors.rightMargin:12;anchors.verticalCenter:parent.verticalCenter;width:115;height:36;radius:3;color:"#c5b6df";Text {anchors.centerIn:parent;text:"Confirm ↵";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:11;color:"#222737"}MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:root.confirm()}}
   }
  }
 }
 PanelWindow {
  visible:root.active && root.notificationsOpen;anchors {top:true;bottom:true;right:true}margins {top:45;bottom:12;right:12}implicitWidth:410
  exclusionMode:ExclusionMode.Ignore
  WlrLayershell.layer:WlrLayer.Overlay
  WlrLayershell.keyboardFocus:WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace:"tideglass-notifications";color:"transparent"
  NotificationPanel {mode:"notifications";backend:"@STUDIO_APP@/themes/extras/pixel/backend.py";x:0;y:0;width:parent.width;height:parent.height;focus:true;Keys.onEscapePressed:root.notificationsOpen=false}
 }
}
