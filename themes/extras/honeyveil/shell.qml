import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
ShellRoot {
 id:root
 property string selected:""
 property var layouts:({})
 property bool opened:false
 property bool notificationsOpen:false
 property string mode:"Apps"
 property string query:""
 property var external:[]
 property string monitorName:""
 readonly property bool active:selected==="honeyveil"
 readonly property var dock:(layouts[selected] || []).find(w=>w.kind==="dock" && w.enabled) || null
 readonly property var apps:DesktopEntries.applications.values.filter(e=>!e.noDisplay)
 readonly property var pinned:{let a=[];for(let group of [['kitty'],['org.kde.dolphin','org.gnome.Nautilus'],['firefox','com.google.Chrome'],['spotify','com.spotify.Client'],['code','com.visualstudio.code']]){let e=apps.find(e=>group.includes(e.id));if(e)a.push(e);}return a;}
 readonly property var results:{let q=query.toLowerCase();if(mode==="Run")return query.trim() ? [{name:query,detail:"Run command",value:query}]:[];let a=mode==="Apps" ? apps:external;return a.filter(e=>(e.name+' '+(e.genericName || e.detail || '')).toLowerCase().includes(q)).slice(0,80);}
 onSelectedChanged:if(!active){opened=false;notificationsOpen=false;}
 FileView {path:"@STUDIO_STATE@/current";watchChanges:true;onLoaded:root.selected=text().trim();onFileChanged:reload()}
 FileView {path:"@STUDIO_CONFIG@/widgets.json";watchChanges:true;onLoaded:{try{root.layouts=JSON.parse(text());}catch(e){}}onFileChanged:reload()}
 function setMode(value){mode=value;query="";list.currentIndex=0;if(value==="Files" || value==="Windows"){data.command=["python3","@STUDIO_APP@/themes/extras/honeyveil/backend.py",value.toLowerCase()];data.running=true;}Qt.callLater(()=>search.forceActiveFocus());}
 function launch(index){let e=results[index];if(!e)return;if(mode==="Apps")e.execute();else if(mode==="Files")Quickshell.execDetached(["xdg-open",e.value]);else if(mode==="Windows")Quickshell.execDetached(["hyprctl","dispatch","focuswindow","address:"+e.value]);else Quickshell.execDetached(["bash","-lc",e.value]);opened=false;}
 IpcHandler {target:"notifications";function toggle():void {if(root.active)root.notificationsOpen=!root.notificationsOpen;}}
 IpcHandler {target:"launcher";function toggle():void {if(!root.active)return;if(root.opened){root.opened=false;return;}monitor.running=true;}}
 Process {id:monitor;command:["hyprctl","activeworkspace","-j"];stdout:StdioCollector {onStreamFinished:{try{root.monitorName=JSON.parse(text).monitor || "";}catch(e){}root.setMode("Apps");root.opened=true;}}}
 Process {id:data;stdout:StdioCollector {onStreamFinished:{try{root.external=JSON.parse(text);}catch(e){root.external=[];}}}}
 PanelWindow {
  visible:root.opened && root.active
  screen:Quickshell.screens.find(s=>s.name===root.monitorName) || Quickshell.screens[0]
  anchors.top:true;margins.top:36
  implicitWidth:700;implicitHeight:290
  exclusionMode:ExclusionMode.Ignore
  WlrLayershell.layer:WlrLayer.Overlay
  WlrLayershell.keyboardFocus:WlrKeyboardFocus.Exclusive
  WlrLayershell.namespace:"honeyveil-launcher"
  color:"transparent"
  Rectangle {anchors.fill:parent;color:"#f51e1e2e";radius:10;border.width:2;border.color:"#c4b58c"
   Text {x:22;y:22;text:"";color:"#cdd6f4";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:16}
   TextInput {id:search;x:52;y:20;width:parent.width-75;height:27;color:"#cdd6f4";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:14;focus:true;text:root.query;onTextEdited:{root.query=text;list.currentIndex=0;}Keys.onEscapePressed:root.opened=false;Keys.onReturnPressed:root.launch(list.currentIndex);Keys.onDownPressed:list.currentIndex=Math.min(root.results.length-1,list.currentIndex+1);Keys.onUpPressed:list.currentIndex=Math.max(0,list.currentIndex-1);Keys.onTabPressed:root.setMode(["Apps","Run","Files","Windows"][( ["Apps","Run","Files","Windows"].indexOf(root.mode)+1)%4])
    Text {visible:!search.text && !search.activeFocus;text:"Search…";color:"#9399b2";font:search.font}
   }
   Row {x:22;y:59;spacing:10
    Repeater {model:["Apps","Run","Files","Windows"]
     Rectangle {required property string modelData;width:156;height:42;radius:8;color:root.mode===modelData ? "#45405f":"#292939"
      Text {anchors.centerIn:parent;text:({Apps:"󰀻 ",Run:" ",Files:" ",Windows:"󰖲 "})[parent.modelData]+parent.modelData;color:root.mode===parent.modelData ? "#f5c2e7":"#cdd6f4";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:13}
      MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:root.setMode(parent.modelData)}
     }
    }
   }
   ListView {id:list;x:22;y:111;width:parent.width-44;height:parent.height-125;clip:true;model:root.results;currentIndex:0
    delegate:Rectangle {id:row;required property var modelData;required property int index;width:list.width;height:48;radius:8;color:list.currentIndex===index ? "#45405f":"transparent"
     Image {visible:root.mode==="Apps";x:12;y:14;width:20;height:20;source:root.mode==="Apps" ? Quickshell.iconPath(row.modelData.icon || "application-x-executable"):""}
     Text {x:44;anchors.verticalCenter:parent.verticalCenter;width:parent.width-55;text:row.modelData.name;textFormat:Text.PlainText;elide:Text.ElideRight;color:list.currentIndex===row.index ? "#f5c2e7":"#cdd6f4";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:14}
     MouseArea {anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onPositionChanged:list.currentIndex=row.index;onClicked:root.launch(row.index)}
    }
   }
  }
 }
 PanelWindow {
  visible:root.active && root.notificationsOpen
  anchors {top:true;right:true}
  margins {top:35;right:8}
  implicitWidth:410;implicitHeight:520
  exclusionMode:ExclusionMode.Ignore
  WlrLayershell.layer:WlrLayer.Overlay
  WlrLayershell.keyboardFocus:WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace:"honeyveil-notifications"
  color:"transparent"
  NotificationPanel {mode:"notifications";backend:"@STUDIO_APP@/themes/extras/pixel/backend.py";x:0;y:0;width:parent.width;height:parent.height;focus:true;Keys.onEscapePressed:root.notificationsOpen=false}
 }
 Variants {model:Quickshell.screens
  PanelWindow {
   required property var modelData
   screen:modelData
   visible:root.active && root.dock!==null
   anchors.bottom:true;margins.bottom:5
   implicitWidth:dockRow.implicitWidth+14;implicitHeight:50
   exclusionMode:ExclusionMode.Ignore
   WlrLayershell.layer:WlrLayer.Top
   WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
   WlrLayershell.namespace:"honeyveil-dock"
   color:"transparent"
   Rectangle {anchors.fill:parent;color:"#e611111b";border.color:"#c4b58c";border.width:2;radius:10}
   Row {id:dockRow;anchors.centerIn:parent;spacing:5
    Repeater {model:root.pinned
     Rectangle {id:tile;required property var modelData;width:43;height:40;radius:6;color:hover.containsMouse ? "#45475a":"#282838"
      Image {anchors.centerIn:parent;width:hover.containsMouse ? 32:28;height:width;source:Quickshell.iconPath(tile.modelData.icon || "application-x-executable");Behavior on width {NumberAnimation {duration:120}}}
      MouseArea {id:hover;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:tile.modelData.execute()}
     }
    }
    Rectangle {width:36;height:40;radius:6;color:"#282838";Text {anchors.centerIn:parent;text:"󰀻";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:22;color:"#f9e2af"}MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:root.opened=!root.opened}}
   }
  }
 }
}
