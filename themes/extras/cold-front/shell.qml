import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
ShellRoot {
    id:root
    property string selected:""
    property bool opened:false
    property string query:""
    property string monitorName:""
    readonly property var apps:DesktopEntries.applications.values.filter(e=>!e.noDisplay)
    readonly property var groups:[['org.kde.dolphin','org.gnome.Nautilus'],['com.google.Chrome','org.chromium.Chromium','chromium','firefox'],['com.spotify.Client','spotify','spotify-launcher','rice-studio'],['com.visualstudio.code','code','codium','org.kde.kate','org.gnome.TextEditor','nvim'],['Alacritty','alacritty','kitty']]
    readonly property var pinned:{
        let result=[];
        for(let aliases of groups){let app=null;for(let id of aliases){app=apps.find(e=>e.id.toLowerCase()===id.toLowerCase());if(app)break;}if(app && !result.some(e=>e.id===app.id))result.push(app);}
        return result;
    }
    readonly property var results:{
        let q=query.toLowerCase();let list=apps.filter(e=>(e.name+' '+e.genericName).toLowerCase().includes(q));
        list.sort((a,b)=>{let aa=pinned.findIndex(e=>e.id===a.id),bb=pinned.findIndex(e=>e.id===b.id);return (aa<0 ? 999:aa)-(bb<0 ? 999:bb) || a.name.localeCompare(b.name);});return list;
    }
    onSelectedChanged:if(selected!=="cold-front")opened=false
    FileView {path:"@STUDIO_STATE@/current";watchChanges:true;onLoaded:root.selected=text().trim();onFileChanged:reload()}
    IpcHandler {target:"launcher";function toggle():void {if(root.selected!=="cold-front")return;if(root.opened){root.opened=false;return;}if(!monitorQuery.running)monitorQuery.running=true;}}
    Process {
        id:monitorQuery
        command:["hyprctl","activeworkspace","-j"]
        stdout:StdioCollector {onStreamFinished:{try{root.monitorName=JSON.parse(text).monitor || "";}catch(e){}root.query="";root.opened=true;entries.currentIndex=0;Qt.callLater(()=>search.forceActiveFocus());}}
    }
    function launch(index){if(results[index])results[index].execute();opened=false;}
    PanelWindow {
        id:launcher
        visible:root.opened && root.selected==="cold-front"
        screen:Quickshell.screens.find(s=>s.name===root.monitorName) || Quickshell.screens[0]
        implicitWidth:640;implicitHeight:560
        exclusionMode:ExclusionMode.Ignore
        WlrLayershell.layer:WlrLayer.Overlay
        WlrLayershell.keyboardFocus:WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace:"cold-front-launcher"
        color:"transparent"
        Rectangle {
            anchors.fill:parent;color:"#e62b3742";border.color:"#65b7ed";border.width:2;radius:2
            Rectangle {
                x:2;y:2;width:parent.width/2-2;height:parent.height-4;color:"#7a94b4"
                Image {anchors.fill:parent;source:"file://@STUDIO_APP@/themes/extras/cold-front/wallpaper.png";fillMode:Image.PreserveAspectCrop;opacity:.55}
            }
            Item {
                x:parent.width/2;y:2;width:parent.width/2-2;height:parent.height-4
                Rectangle {width:parent.width;height:40;color:"#d8283038";border.color:"#465b6c"
                    TextInput {
                        id:search;x:12;width:parent.width-24;anchors.verticalCenter:parent.verticalCenter;focus:true;color:"#d4dce2";font.family:"Iosevka Nerd Font";font.pixelSize:13
                        text:root.query;onTextEdited:{root.query=text;entries.currentIndex=0;}
                        Keys.onEscapePressed:root.opened=false
                        Keys.onReturnPressed:root.launch(entries.currentIndex)
                        Keys.onDownPressed:entries.currentIndex=Math.min(root.results.length-1,entries.currentIndex+1)
                        Keys.onUpPressed:entries.currentIndex=Math.max(0,entries.currentIndex-1)
                    }
                }
                ListView {
                    id:entries;y:43;width:parent.width;height:parent.height-43;clip:true;model:root.results;currentIndex:0;boundsBehavior:Flickable.StopAtBounds
                    delegate:Rectangle {
                        id:row
                        required property var modelData
                        required property int index
                        width:entries.width;height:53
                        color:entries.currentIndex===index ? "#e0161b1f":"transparent"
                        border.color:entries.currentIndex===index ? "#8b9b8b":"transparent"
                        Image {x:15;anchors.verticalCenter:parent.verticalCenter;width:17;height:17;source:Quickshell.iconPath(row.modelData.icon || 'application-x-executable');fillMode:Image.PreserveAspectFit}
                        Text {
                            x:45;width:parent.width-55;anchors.verticalCenter:parent.verticalCenter
                            text:row.modelData.name+(row.modelData.genericName ? ' ('+row.modelData.genericName+')':'')
                            textFormat:Text.PlainText;elide:Text.ElideRight;color:"#d4b293";font.family:"Iosevka Nerd Font";font.pixelSize:13
                        }
                        MouseArea {anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onPositionChanged:entries.currentIndex=row.index;onClicked:root.launch(row.index)}
                    }
                    Text {anchors.centerIn:parent;visible:entries.count===0;text:"No matching apps";font.family:"Iosevka Nerd Font";font.pixelSize:13;color:"#c4cdd4"}
                }
            }
        }
    }
    Variants {
        model:Quickshell.screens
        PanelWindow {
            required property var modelData
            screen:modelData
            visible:root.selected==="cold-front"
            anchors.bottom:true
            margins.bottom:8
            implicitWidth:dockRow.implicitWidth+18;implicitHeight:48
            exclusionMode:ExclusionMode.Ignore
            WlrLayershell.layer:WlrLayer.Top
            WlrLayershell.namespace:"cold-front-dock"
            WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
            color:"transparent"
            Rectangle {anchors.fill:parent;color:"#50233140";radius:3}
            Row {
                id:dockRow;anchors.centerIn:parent;spacing:7
                Repeater {
                    model:root.pinned
                    Item {
                        id:tile
                        required property var modelData
                        width:38;height:40
                        Image {anchors.centerIn:parent;width:hover.containsMouse ? 33:29;height:width;source:Quickshell.iconPath(tile.modelData.icon || 'application-x-executable');fillMode:Image.PreserveAspectFit;Behavior on width {NumberAnimation {duration:120;easing.type:Easing.OutCubic}}}
                        Rectangle {anchors.bottom:parent.bottom;anchors.horizontalCenter:parent.horizontalCenter;width:4;height:2;color:"#6dbdf2";visible:hover.containsMouse}
                        MouseArea {id:hover;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:tile.modelData.execute()}
                        Text {anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:parent.top;visible:hover.containsMouse;text:tile.modelData.name;textFormat:Text.PlainText;color:"#e3ebf1";font.family:"Iosevka Nerd Font";font.pixelSize:10}
                    }
                }
            }
        }
    }
}
