import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
ShellRoot {
    id: studio
    property var library: ({profiles:[],bars:[],terminals:[],widgets:{},history:[],preferences:{},current:"",widgetTypes:[]})
    property string selectedKey:""
    readonly property var selected:library.profiles.find(p=>p.key===selectedKey) || ({title:"Your collection",image:"",profile:{theme:{colors:{}}}})
    property var draft:({theme:{colors:{}}})
    property var widgetDraft:[]
    property bool dirty:false
    property bool widgetDirty:false
    property string previewOverride:""
    readonly property string canvasImage:draft.wallpaper===selected.profile.wallpaper ? selected.image:previewOverride
    property bool loaded:false
    property bool showWelcome:true
    property bool reducedMotion:false
    property bool busy:false
    property string busyLabel:"Reading your collection"
    property string error:""
    property string page:"collection"
    property real pageOpacity:1
    property real pageOffset:0
    property var pending:({})
    property double now:Date.now()/1000
    readonly property bool previewActive:pending.status==="preview" || pending.status==="starting"
    readonly property int secondsLeft:Math.max(0,Math.ceil((pending.deadline || 0)-now))
    property string filter:""
    property string toastText:""
    property bool toastVisible:false
    property int nextId:0
    property var requests:({})
    property string pendingSelect:""
    property bool favoritesOnly:false
    property bool capturing:false
    property bool captureVideo:false
    property int captureCountdown:0
    property var favorites:library.preferences.favorites || []
    function favorite(key){let a=favorites.slice();let i=a.indexOf(key);if(i>=0)a.splice(i,1);else a.push(key);let l=clone(library);l.preferences.favorites=a;library=l;request("preferences",{favorites:a},"",true);}
    function capture(video){if(selectedKey!==library.current){notify("Select the active rice to capture it.");return;}captureVideo=video;captureCountdown=3;captureTimer.start();}
    Timer {id:captureTimer;interval:1000;repeat:true;onTriggered:{studio.captureCountdown--;if(studio.captureCountdown<=0){stop();studio.capturing=true;window.visible=false;captureDelay.start();}}}
    Timer {id:captureDelay;interval:450;onTriggered:studio.request("capture",{key:studio.selectedKey,video:studio.captureVideo},"Capturing your desktop")}
    property string colorKey:""
    property var confirmAction:null
    readonly property int duration:reducedMotion ? 0:240
    function clone(value){return JSON.parse(JSON.stringify(value));}
    function request(method,params,label,quiet){
        if(busy && !quiet)return;
        let id=++nextId;requests[id]={method:method,quiet:!!quiet};
        if(!quiet){busy=true;busyLabel=label || "Working on your desktop";}
        bridge.write(JSON.stringify({id:id,method:method,params:params || {}})+"\n");
    }
    function receive(line){
        let m;try{m=JSON.parse(line);}catch(e){return;}
        if(m.event==="ready"){request("bootstrap",{},"Reading your collection",true);return;}
        let req=requests[m.id] || {};delete requests[m.id];
        if(!req.quiet)busy=false;
        if(req.method==="capture"){capturing=false;window.visible=true;window.requestActivate();}
        if(!m.ok){error=m.error || "The request could not be completed.";if(!loaded)bootError.visible=true;else notify(error);return;}
        let data=m.result || {};
        if(req.method==="bootstrap"){
            let first=!loaded,previous=selectedKey;library=data;pending=data.pending || {};reducedMotion=!!data.preferences.reduce_motion;loaded=true;if(first)showWelcome=!data.preferences.skip_welcome;choose(!first && data.profiles.some(p=>p.key===previous) ? previous:data.current && data.profiles.some(p=>p.key===data.current) ? data.current:data.profiles[0].key,true);return;
        }
        if(data.notes){let l=clone(library);l.notes=data.notes;library=l;}
        if(data.media){let l=clone(library);l.media=data.media;library=l;}
        if(data.health){let l=clone(library);l.health=data.health;library=l;}
        if(data.windowMode){let updated=clone(library);updated.windowMode=data.windowMode;library=updated;}
        if(data.previewUrl!==undefined){previewOverride=data.previewUrl;return;}
        if(data.profiles){let wanted=data.selected || selectedKey;library=data;pending=data.pending || {};choose(wanted,true);}
        else {
            if(data.history){let updated=clone(library);updated.history=data.history;library=updated;}
            if(data.current && data.current!==library.current){let updated=clone(library);updated.current=data.current;library=updated;}
            if(data.pending){let previous=pending.status;pending=data.pending;if(previous==="preview" && pending.status==="reverted")notify("Your previous desktop is back.");}
        }
        if(req.method!=="status" && req.method!=="preferences" && req.method!=="open_config" && req.method!=="wallpaper_preview")notify(({save_profile:"Appearance saved · checkpoint created",save_widgets:"Widget layout saved",duplicate:"A new preset is ready",checkpoint:"Recovery checkpoint saved",restore:"Checkpoint restored",keep:"This desktop is yours to keep",revert:"Previous desktop restored",rescue:"Main desktop recovered",preview:"Preview is live · choose Keep or Revert"})[req.method] || "Done.");
    }
    function choose(key,force){
        if(!force && key!==selectedKey && (dirty || widgetDirty)){pendingSelect=key;ask("Unsaved changes","Discard your unsaved appearance and widget drafts?",function(){choose(pendingSelect,true);});return;}
        let row=library.profiles.find(p=>p.key===key);if(!row)return;
        selectedKey=key;draft=clone(row.profile);widgetDraft=clone((library.widgets || {})[key] || []);dirty=false;widgetDirty=false;previewOverride="";
        let visibleRows=library.profiles.filter(p=>(p.title+' '+p.description).toLowerCase().includes(filter.toLowerCase()));let index=visibleRows.findIndex(p=>p.key===key);
        if(index>=0)Qt.callLater(function(){collection.positionViewAtIndex(index,ListView.Contain);});
    }
    function setField(key,value){let p=clone(draft);p[key]=value;draft=p;dirty=true;if(key==="wallpaper"){previewOverride="";request("wallpaper_preview",{path:value},"",true);}}
    function setTheme(key,value){let p=clone(draft);p.theme[key]=value;draft=p;dirty=true;}
    function setColor(key,value){let p=clone(draft);p.theme.colors[key]=value;draft=p;dirty=true;}
    function saveAppearance(){request("save_profile",{key:selectedKey,profile:draft},"Saving your appearance");}
    function addWidget(kind){let list=clone(widgetDraft);list.push({id:"widget-"+Date.now(),kind:kind,x:64+list.length*24,y:80+list.length*24,width:320,height:200,enabled:true,text:""});widgetDraft=list;widgetDirty=true;}
    function updateWidget(index,patch){
        let list=clone(widgetDraft);Object.keys(patch).forEach(k=>list[index][k]=patch[k]);let item=list[index];
        item.width=Math.max(180,Math.min(1400,Number(item.width)));item.height=Math.max(100,Math.min(1000,Number(item.height)));
        item.x=Math.max(0,Math.min(1920-item.width,Number(item.x)));item.y=Math.max(0,Math.min(1080-item.height,Number(item.y)));
        widgetDraft=list;widgetDirty=true;
    }
    function deleteWidget(index){let list=clone(widgetDraft);list.splice(index,1);widgetDraft=list;widgetDirty=true;}
    function saveWidgets(){request("save_widgets",{key:selectedKey,items:widgetDraft},"Saving the widget layout");}
    function preview(){if(dirty || widgetDirty){notify("Save your draft changes before previewing.");return;}request("preview",{key:selectedKey},"Preparing "+selected.title);}
    function notify(text){toastText=text;toastVisible=true;toastTimer.restart();}
    function ask(title,body,action){confirmTitle.text=title;confirmBody.text=body;confirmAction=action;confirmDialog.open();}
    function setPage(value){page=value;if(!reducedMotion)pageAnimation.restart();}
    function toggleMotion(){reducedMotion=!reducedMotion;request("preferences",{reduce_motion:reducedMotion},"",true);}
    function enter(){showWelcome=false;request("preferences",{skip_welcome:welcome.skipNext},"",true);}
    function pickColor(key){colorKey=key;colorPicker.selectedColor=draft.theme.colors[key] || "#737374";colorPicker.open();}
    Process {
        id:bridge
        command:["python3",Qt.resolvedUrl("bridge.py").toString().replace("file://", "")]
        stdinEnabled:true
        running:true
        stdout:SplitParser {onRead:data=>studio.receive(data)}
        onExited:{studio.busy=false;studio.error="The local backend stopped. Reopen Rice Studio or run rice-studio-recover.";if(studio.loaded)studio.notify(studio.error);else bootError.visible=true;}
    }
    Process {id:placement;command:["python3",Qt.resolvedUrl("place-window.py").toString().replace("file://","")]}
    Timer {interval:600;running:true;onTriggered:placement.running=true}
    IpcHandler {
        target:"studio"
        function focus():void {window.visible=true;window.requestActivate();if(studio.loaded && !studio.dirty && !studio.widgetDirty)studio.request("bootstrap",{},"",true);}
        function status():string {return JSON.stringify({loaded:studio.loaded,page:studio.page,welcome:studio.showWelcome,profiles:studio.library.profiles.length,selected:studio.selectedKey,dirty:studio.dirty,widgetDirty:studio.widgetDirty,busy:studio.busy,geometry:{window:window.height,pane:workspacePane.height,footerY:footer.y,footerH:footer.height}});}
        function select(key:string):void {studio.choose(key,false);}
        function home():void {studio.showWelcome=true;}
        function view(page:string):void {if(["collection","appearance","widgets","media","health","recovery","files"].indexOf(page)>=0){studio.showWelcome=false;studio.setPage(page);}}
    }
    Timer {interval:1800;running:studio.loaded && !studio.busy;repeat:true;onTriggered:studio.request("status",{},"",true)}
    Timer {interval:250;running:studio.previewActive;repeat:true;onTriggered:studio.now=Date.now()/1000}
    Timer {id:toastTimer;interval:4200;onTriggered:studio.toastVisible=false}
    ParallelAnimation {id:pageAnimation;NumberAnimation {target:studio;property:"pageOpacity";from:0;to:1;duration:studio.duration} NumberAnimation {target:studio;property:"pageOffset";from:4;to:0;duration:studio.duration;easing.type:Easing.OutCubic}}
    Window {
        id:window
        title:"Rice Studio · Portable"
        visible:true
        width:1400;height:900;minimumWidth:1080;minimumHeight:680
        color:"#101011"
        onClosing:Qt.quit()
        Shortcut {sequence:"Ctrl+F";onActivated:search.forceActiveFocus()}
        Shortcut {sequence:"Ctrl+1";onActivated:studio.setPage("collection")}
        Shortcut {sequence:"Ctrl+2";onActivated:studio.setPage("appearance")}
        Shortcut {sequence:"Ctrl+3";onActivated:studio.setPage("media")}
        Shortcut {sequence:"Escape";onActivated:{if(studio.captureCountdown>0){captureTimer.stop();studio.captureCountdown=0;}else if(studio.filter!=="")search.text="";}}
        Shortcut {sequence:"Ctrl+S";enabled:studio.loaded && !studio.showWelcome;onActivated:studio.page==="widgets" ? studio.saveWidgets():studio.page==="appearance" ? studio.saveAppearance():studio.notify("Open Edit or Widgets to save changes.")}
        Rectangle {
            anchors.fill:parent;color:"#101113";visible:studio.loaded && !studio.showWelcome
            RowLayout {
                anchors.fill:parent;spacing:0
                Rectangle {
                    Layout.preferredWidth:188;Layout.fillHeight:true;color:"#0b0c0e"
                    ColumnLayout {
                        anchors.fill:parent;anchors.margins:14;spacing:10
                        Item {Layout.fillWidth:true;Layout.preferredHeight:53
                            Text {textFormat:Text.PlainText;x:3;y:2;text:"Rice Studio";font.family:"JetBrains Mono";font.pixelSize:23;color:"#e2ded6"}
                            Text {textFormat:Text.PlainText;x:4;y:32;text:"WORKSHOP / 02";font.family:"JetBrains Mono";font.pixelSize:9;font.letterSpacing:1.4;color:"#6f6d69"}
                        }
                        Rectangle {Layout.fillWidth:true;height:1;color:"#2c2c30"}
                        Field {id:search;Layout.fillWidth:true;placeholderText:"Filter presets";onTextChanged:studio.filter=text}
                        RowLayout {Layout.fillWidth:true;Text {textFormat:Text.PlainText;text:"PRESETS";font.family:"JetBrains Mono";font.pixelSize:10;color:"#77767a"} Item {Layout.fillWidth:true} Text {textFormat:Text.PlainText;text:studio.library.profiles.length;font.family:"JetBrains Mono";font.pixelSize:10;color:"#77767a"}}
                        ListView {
                            id:collection
                            Layout.fillWidth:true;Layout.fillHeight:true;clip:true;spacing:2
                            model:studio.library.profiles.filter(p=>(p.title+' '+p.description).toLowerCase().includes(studio.filter.toLowerCase()))
                            delegate:Rectangle {
                                id:presetCard
                                required property var modelData
                                width:collection.width;height:35
                                color:modelData.key===studio.selectedKey ? "#242326":cardMouse.containsMouse ? "#19191c":"transparent"
                                Behavior on color {ColorAnimation {duration:studio.duration}}
                                Rectangle {width:2;height:17;x:0;anchors.verticalCenter:parent.verticalCenter;color:"#d6ab7d";visible:presetCard.modelData.key===studio.selectedKey}
                                Text {textFormat:Text.PlainText;x:11;anchors.verticalCenter:parent.verticalCenter;width:parent.width-28;text:presetCard.modelData.title;color:presetCard.modelData.key===studio.selectedKey ? "#e2ddd4":"#9e9ca0";font.family:"JetBrains Mono";font.pixelSize:14;elide:Text.ElideRight}
                                Text {textFormat:Text.PlainText;anchors.right:parent.right;anchors.rightMargin:6;anchors.verticalCenter:parent.verticalCenter;text:"•";visible:presetCard.modelData.key===studio.library.current;color:"#d6ab7d";font.pixelSize:12}
                                MouseArea {id:cardMouse;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:studio.choose(presetCard.modelData.key,false)}
                            }
                            ScrollBar.vertical:ScrollBar {width:3}
                            Text {textFormat:Text.PlainText;anchors.centerIn:parent;visible:collection.count===0;text:"No match";font.family:"JetBrains Mono";font.pixelSize:13;color:"#79777a"}
                        }
                        Rectangle {Layout.fillWidth:true;height:1;color:"#2c2c30"}
                        ActionButton {Layout.fillWidth:true;quiet:true;text:"+ Clone preset";onClicked:{duplicateName.text=studio.selected.title+" copy";duplicateDialog.open();}}
                        RowLayout {Layout.fillWidth:true;spacing:0;ActionButton {quiet:true;text:"Start";implicitWidth:64;onClicked:studio.showWelcome=true} Item {Layout.fillWidth:true} ActionButton {quiet:true;text:studio.reducedMotion ? "Motion −":"Motion +";implicitWidth:86;onClicked:studio.toggleMotion()}}
                    }
                }
                Rectangle {Layout.preferredWidth:1;Layout.fillHeight:true;color:"#2c2c30"}
                ColumnLayout {
                    Layout.fillWidth:true;Layout.fillHeight:true;spacing:0
                    Item {
                        Layout.fillWidth:true;Layout.preferredHeight:65
                        Text {textFormat:Text.PlainText;x:22;anchors.verticalCenter:parent.verticalCenter;text:studio.selected.title;font.family:"C059";font.pixelSize:25;color:"#dedad1"}
                        Text {textFormat:Text.PlainText;anchors.right:parent.right;anchors.verticalCenter:parent.verticalCenter;anchors.rightMargin:22;text:studio.dirty || studio.widgetDirty ? "●  unsaved":studio.selectedKey===studio.library.current ? "●  on desktop":studio.selectedKey==="main" ? "recovery baseline":"not applied";font.family:"JetBrains Mono";font.pixelSize:12;color:studio.dirty || studio.widgetDirty ? "#d6ab7d":"#78777a"}
                    }
                    RowLayout {
                        Layout.fillWidth:true;Layout.leftMargin:16;Layout.rightMargin:22;Layout.bottomMargin:12;spacing:5
                        Repeater {model:[{id:"collection",name:"Collection"},{id:"appearance",name:"Edit"},{id:"widgets",name:"Widgets"},{id:"media",name:"Captures"},{id:"health",name:"Setup"},{id:"recovery",name:"Recovery"},{id:"files",name:"Files"}]
                            ActionButton {
                                id:tab
                                required property var modelData
                                text:modelData.name;quiet:true;implicitHeight:29;implicitWidth:90
                                reducedMotion:studio.reducedMotion
                                contentItem:Text {textFormat:Text.PlainText;text:tab.text;font.family:"JetBrains Mono";font.pixelSize:14;color:studio.page===tab.modelData.id ? "#e0dbd1":"#737277";verticalAlignment:Text.AlignVCenter;horizontalAlignment:Text.AlignHCenter}
                                background:Rectangle {color:tab.hovered ? "#1c1c20":"transparent";Rectangle {anchors.bottom:parent.bottom;width:parent.width;height:1;color:"#d6ab7d";visible:studio.page===tab.modelData.id}}
                                onClicked:studio.setPage(modelData.id)
                            }
                        }
                        Item {Layout.fillWidth:true}
                    }
                    Item {
                        id:workspacePane
                        Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:0;clip:true
                        StackLayout {
                            id:pageStack
                            anchors.fill:parent;anchors.leftMargin:22;anchors.rightMargin:22
                            currentIndex:["collection","appearance","widgets","media","health","recovery","files"].indexOf(studio.page)
                            opacity:studio.pageOpacity;transform:Translate {y:studio.pageOffset}
                            GalleryPage {Layout.minimumWidth:0;Layout.minimumHeight:0;studio:studio}
                            AppearancePage {Layout.minimumWidth:0;Layout.minimumHeight:0;studio:studio}
                            WidgetsPage {Layout.minimumWidth:0;Layout.minimumHeight:0;id:widgetPage;studio:studio}
                            MediaPage {Layout.minimumWidth:0;Layout.minimumHeight:0;studio:studio}
                            HealthPage {Layout.minimumWidth:0;Layout.minimumHeight:0;studio:studio}
                            RecoveryPage {Layout.minimumWidth:0;Layout.minimumHeight:0;studio:studio}
                            FilesPage {Layout.minimumWidth:0;Layout.minimumHeight:0;studio:studio}
                        }
                    }
                    Rectangle {
                        id:footer
                        Layout.fillWidth:true;Layout.preferredHeight:55;Layout.minimumHeight:55;Layout.maximumHeight:55;color:"#0e0f11"
                        Rectangle {anchors.top:parent.top;width:parent.width;height:1;color:"#2c2c30"}
                        Rectangle {visible:studio.previewActive;anchors.top:parent.top;width:parent.width*Math.min(1,studio.secondsLeft/30);height:2;color:"#d6ab7d";Behavior on width {NumberAnimation {duration:studio.reducedMotion ? 0:230}}}
                        RowLayout {
                            anchors.fill:parent;anchors.leftMargin:22;anchors.rightMargin:22;spacing:9
                            ActionButton {text:studio.previewActive ? "Preview running":"Preview · 30s";primary:true;enabled:!studio.busy && !studio.previewActive;reducedMotion:studio.reducedMotion;onClicked:studio.preview()}
                            ActionButton {text:"Keep";visible:studio.previewActive;enabled:!studio.busy && studio.pending.status==="preview";onClicked:studio.request("keep",{},"Keeping this desktop")}
                            ActionButton {text:"Revert";visible:studio.previewActive;enabled:!studio.busy;onClicked:studio.request("revert",{},"Restoring your desktop")}
                            Item {Layout.fillWidth:true}
                            Text {textFormat:Text.PlainText;text:studio.previewActive ? studio.secondsLeft+"s until revert":"Changes stay in the editor until previewed.";color:"#77767a";font.family:"JetBrains Mono";font.pixelSize:12}
                        }
                    }
                }
            }
        }
        Rectangle {z:99;visible:studio.captureCountdown>0;anchors.centerIn:parent;width:440;height:160;color:"#191a1c";border.color:"#d6ab7d"
            MouseArea {anchors.fill:parent}
            Column {anchors.centerIn:parent;spacing:12;Text {anchors.horizontalCenter:parent.horizontalCenter;text:"Capture starts in "+studio.captureCountdown;color:"#efe7dc";font.pixelSize:26} Text {text:studio.captureVideo ? "8 seconds · focused monitor · no audio":"Still image · focused monitor";color:"#aaa49a";font.pixelSize:13}}
        }
        Welcome {id:welcome;anchors.fill:parent;studio:studio;visible:studio.loaded && studio.showWelcome}
        Rectangle {
            id:splash
            anchors.fill:parent;color:"#111112";visible:opacity>0
            opacity:studio.loaded ? 0:1
            Behavior on opacity {NumberAnimation {duration:studio.duration}}
            Column {anchors.centerIn:parent;spacing:22
                Rectangle {width:64;height:64;radius:0;color:"#d6ab7d";anchors.horizontalCenter:parent.horizontalCenter;Text {textFormat:Text.PlainText;anchors.centerIn:parent;text:"rs";font.family:"JetBrains Mono";font.pixelSize:36;font.bold:true;color:"#131314"}}
                Text {textFormat:Text.PlainText;anchors.horizontalCenter:parent.horizontalCenter;text:"Rice Studio";font.family:"JetBrains Mono";font.pixelSize:31;font.weight:Font.DemiBold;color:"#e0e0e1"}
                Text {textFormat:Text.PlainText;anchors.horizontalCenter:parent.horizontalCenter;text:"Reading your collection";font.family:"JetBrains Mono";font.pixelSize:11;color:"#9b9b9c"}
                BusyIndicator {anchors.horizontalCenter:parent.horizontalCenter;running:!studio.loaded && !studio.reducedMotion;visible:!studio.reducedMotion;palette.dark:"#d6ab7d";width:32;height:32}
                Column {id:bootError;visible:false;spacing:12;Text {textFormat:Text.PlainText;width:420;wrapMode:Text.Wrap;text:studio.error;color:"#d1b59b";font.pixelSize:12;} ActionButton {text:"Close Rice Studio";onClicked:Qt.quit()}}
            }
        }
        Rectangle {
            anchors.fill:parent;color:"#df0f0f10";visible:studio.busy
            MouseArea {anchors.fill:parent}
            Rectangle {anchors.centerIn:parent;width:Math.min(parent.width-70,470);height:210;radius:0;color:"#181819";border.color:"#3d3d3e"
                Column {anchors.centerIn:parent;spacing:18
                    BusyIndicator {anchors.horizontalCenter:parent.horizontalCenter;running:studio.busy && !studio.reducedMotion;visible:!studio.reducedMotion;width:34;height:34}
                    Text {textFormat:Text.PlainText;anchors.horizontalCenter:parent.horizontalCenter;text:studio.busyLabel;color:"#e0e0e1";font.family:"JetBrains Mono";font.pixelSize:20;font.weight:Font.DemiBold}
                    Text {textFormat:Text.PlainText;anchors.horizontalCenter:parent.horizontalCenter;text:"Your recovery track stays available.";color:"#969697";font.pixelSize:12}
                }
            }
        }
        Rectangle {
            anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:parent.bottom;anchors.bottomMargin:studio.toastVisible ? 94:78
            width:Math.min(toastLabel.implicitWidth+42,parent.width-60);height:48;radius:0;color:"#363637";border.color:"#737374";z:10
            visible:opacity>0;opacity:studio.toastVisible ? 1:0
            Behavior on opacity {NumberAnimation {duration:studio.duration}}
            Behavior on anchors.bottomMargin {NumberAnimation {duration:studio.duration;easing.type:Easing.OutCubic}}
            Text {textFormat:Text.PlainText;id:toastLabel;anchors.fill:parent;anchors.margins:16;text:studio.toastText;color:"#e3e3e4";font.family:"JetBrains Mono";font.pixelSize:12;verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight;}
        }
    }
    FileDialog {id:wallpaperPicker;parentWindow:window;title:"Choose a wallpaper";nameFilters:["Wallpapers (*.png *.jpg *.jpeg *.webp *.mp4 *.webm)"];onAccepted:studio.setField("wallpaper",decodeURIComponent(selectedFile.toString().replace(/^file:\/\//,'')))}
    ColorDialog {id:colorPicker;parentWindow:window;title:"Choose a palette color";onAccepted:studio.setColor(studio.colorKey,selectedColor.toString())}
    Dialog {
        id:confirmDialog;parent:window.contentItem;anchors.centerIn:parent;width:420;modal:true;padding:24
        background:Rectangle {color:"#181819";radius:0;border.color:"#474748"}
        contentItem:Column {spacing:16;Text {textFormat:Text.PlainText;id:confirmTitle;width:parent.width;wrapMode:Text.Wrap;color:"#dfdfe0";font.pixelSize:21;font.weight:Font.DemiBold} Text {textFormat:Text.PlainText;id:confirmBody;width:parent.width;wrapMode:Text.Wrap;color:"#a5a5a6";font.pixelSize:13;} Row {spacing:10;ActionButton {text:"Cancel";onClicked:confirmDialog.close()} ActionButton {text:"Continue";primary:true;onClicked:{confirmDialog.close();if(studio.confirmAction)studio.confirmAction();}}}}
    }
    Dialog {
        id:duplicateDialog;parent:window.contentItem;anchors.centerIn:parent;width:420;modal:true;padding:24
        background:Rectangle {color:"#181819";radius:0;border.color:"#474748"}
        contentItem:Column {spacing:16;Text {textFormat:Text.PlainText;text:"Make it your own";color:"#dfdfe0";font.pixelSize:22;font.weight:Font.DemiBold} Text {textFormat:Text.PlainText;width:parent.width;text:"The original preset stays in your collection.";wrapMode:Text.Wrap;color:"#a5a5a6";font.pixelSize:13} Field {id:duplicateName;width:parent.width;placeholderText:"Name your preset"} Row {spacing:10;ActionButton {text:"Cancel";onClicked:duplicateDialog.close()} ActionButton {text:"Create preset";primary:true;onClicked:{duplicateDialog.close();studio.request("duplicate",{key:studio.selectedKey,name:duplicateName.text},"Creating a new preset");}}}}
    }
}
